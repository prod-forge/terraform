resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = var.project
      image = "${var.repository_url}:initial"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]

      environment = [
        {
          name  = "NODE_TLS_REJECT_UNAUTHORIZED"
          value = "0"
        },
        {
          name  = "DATABASE_USER"
          value = var.db_username
        },
        {
          name  = "DATABASE_HOST"
          value = var.db_host
        },
        {
          name  = "DATABASE_NAME"
          value = var.db_name
        },
        {
          name  = "DATABASE_PORT"
          value = var.db_port
        },
        {
          name  = "REDIS_HOST"
          value = var.redis_host
        },
        {
          name  = "REDIS_PORT"
          value = var.redis_port
        },
      ]

      secrets = [
        {
          name      = "DATABASE_PASSWORD"
          valueFrom = "${var.rds_secrets_arn}:password::"
        },
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project}"
          awslogs-region        = "eu-central-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_migration" {
  name              = "/ecs/${var.project}-task-migration"
  retention_in_days = 3
}
