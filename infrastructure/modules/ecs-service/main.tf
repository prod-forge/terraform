############################################################
# GitHub Actions ECS Permissions
############################################################

resource "aws_iam_policy" "ecs_deploy" {
  name = "github-actions-ecs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeClusters",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:ListTaskDefinitions",
          "ecs:TagResource",
          "rds:DescribeDBInstances",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_passrole" {
  name = "github-actions-ecs-passrole-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          "arn:aws:iam::${var.aws_account_id}:role/ecs-task-role",
          "arn:aws:iam::${var.aws_account_id}:role/ecs-task-execution-role",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_deploy" {
  role       = var.github_actions_role_name
  policy_arn = aws_iam_policy.ecs_deploy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_passrole" {
  role       = var.github_actions_role_name
  policy_arn = aws_iam_policy.ecs_passrole.arn
}

############################################################
# ECS Service
############################################################

resource "aws_ecs_service" "app" {
  name            = "${var.project}-service"
  cluster         = var.ecs_cluster_id
  task_definition = var.ecs_task_definition_arn

  desired_count = 1

  lifecycle {
    ignore_changes = [task_definition]
  }

  launch_type = "FARGATE"

  enable_execute_command = true

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.sg_ecs_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = var.project
    container_port   = 3000
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
}
