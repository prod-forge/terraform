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
