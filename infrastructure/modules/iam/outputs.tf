output "task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn

  # Tasks must not start before the secrets policy is attached.
  depends_on = [aws_iam_role_policy_attachment.ecs_secret_attach, aws_iam_role_policy_attachment.ecs_task_execution_role_policy]
}

output "task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

