output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  value = aws_ecs_task_definition.app.family
}

output "log_group_name" {
  description = "CloudWatch log group of the application task"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "migration_log_group_name" {
  description = "CloudWatch log group of the migration task that backend CD registers"
  value       = aws_cloudwatch_log_group.ecs_migration.name
}
