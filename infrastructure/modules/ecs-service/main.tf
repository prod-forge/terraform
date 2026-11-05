############################################################
# GitHub Actions ECS Permissions
############################################################

data "aws_region" "current" {}

locals {
  ecs_arn_prefix = "arn:aws:ecs:${data.aws_region.current.region}:${var.aws_account_id}"

  task_definition_family_arns = [
    "${local.ecs_arn_prefix}:task-definition/${var.task_definition_family}:*",
    "${local.ecs_arn_prefix}:task-definition/${var.migration_task_definition_family}:*",
  ]
}

resource "aws_iam_policy" "ecs_deploy" {
  name = "${var.project}-${var.environment}-github-ecs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Service"
        Effect   = "Allow"
        Action   = ["ecs:UpdateService", "ecs:DescribeServices"]
        Resource = aws_ecs_service.app.id
      },
      {
        Sid      = "RunTask"
        Effect   = "Allow"
        Action   = ["ecs:RunTask", "ecs:TagResource"]
        Resource = local.task_definition_family_arns
      },
      {
        Sid      = "Tasks"
        Effect   = "Allow"
        Action   = ["ecs:DescribeTasks"]
        Resource = "${local.ecs_arn_prefix}:task/${var.ecs_cluster_name}/*"
      },
      {
        Sid      = "ListTasks"
        Effect   = "Allow"
        Action   = ["ecs:ListTasks"]
        Resource = "${local.ecs_arn_prefix}:container-instance/${var.ecs_cluster_name}/*"
        Condition = {
          ArnEquals = { "ecs:cluster" = var.ecs_cluster_id }
        }
      },
      {
        # These actions do not support resource-level permissions.
        Sid    = "TaskDefinitions"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTaskDefinitions",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "ecs_passrole" {
  name = "${var.project}-${var.environment}-github-ecs-passrole-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = var.task_role_arns
        Condition = {
          StringEquals = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_deploy" {
  role       = var.backend_role_name
  policy_arn = aws_iam_policy.ecs_deploy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_passrole" {
  role       = var.backend_role_name
  policy_arn = aws_iam_policy.ecs_passrole.arn
}

############################################################
# ECS Service
############################################################

resource "aws_ecs_service" "app" {
  name            = "${var.project}-${var.environment}-service"
  cluster         = var.ecs_cluster_id
  task_definition = var.ecs_task_definition_arn

  desired_count = var.desired_count

  lifecycle {
    # task_definition is rolled by CD; desired_count is owned by Application Auto Scaling.
    ignore_changes = [task_definition, desired_count]
  }

  # Changing launch_type forces a new service, so it stays FARGATE; see guide/scaling.md for Spot.
  launch_type = "FARGATE"

  enable_execute_command = true
  propagate_tags         = "SERVICE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.sg_ecs_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = var.project
    container_port   = 3000
  }

  dynamic "service_registries" {
    for_each = var.service_discovery_arn == null ? [] : [var.service_discovery_arn]

    content {
      registry_arn = service_registries.value
    }
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds  = 60
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
}
