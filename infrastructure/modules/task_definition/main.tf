locals {
  prefix = "${var.project}-${var.environment}"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = var.project
      image = "${var.repository_url}:${var.image_tag}"

      # The backend drains for 10s and then waits up to 20s for in-flight requests,
      # so 60s leaves headroom before ECS sends SIGKILL.
      stopTimeout = 60

      # NestJS and Prisma write to the filesystem at runtime (temp files, engine cache).
      readonlyRootFilesystem = false

      # Required by ECS Exec and reaps zombie processes.
      linuxParameters = {
        initProcessEnabled = true
      }

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
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
        {
          name  = "REDIS_TLS"
          value = "true"
        },
      ]

      secrets = [
        {
          name      = "DATABASE_PASSWORD"
          valueFrom = "${var.rds_secrets_arn}:password::"
        },
        {
          name      = "REDIS_PASSWORD"
          valueFrom = var.redis_auth_secret_arn
        },
        {
          name      = "JWT_SECRET"
          valueFrom = var.jwt_secret_arn
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
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs" {
  #checkov:skip=CKV_AWS_158: encrypted at rest with the CloudWatch Logs service key; a dedicated CMK for logs is not provisioned yet
  #checkov:skip=CKV_AWS_338: application logs are operational, not audit records; retention is set by var.log_retention_days to bound cost
  name              = "/ecs/${local.prefix}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "ecs_migration" {
  #checkov:skip=CKV_AWS_158: encrypted at rest with the CloudWatch Logs service key; a dedicated CMK for logs is not provisioned yet
  #checkov:skip=CKV_AWS_338: migration logs are operational, not audit records; retention is set by var.log_retention_days to bound cost
  name              = "/ecs/${local.prefix}-task-migration"
  retention_in_days = var.log_retention_days
}
