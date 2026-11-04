output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  value = aws_ecs_task_definition.app.family
}
