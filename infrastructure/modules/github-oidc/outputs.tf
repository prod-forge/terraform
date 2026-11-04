output "backend_role_name" {
  description = "Name of the IAM role assumed by the backend repository"
  value       = aws_iam_role.github["backend"].name
}

output "backend_role_arn" {
  description = "ARN of the IAM role assumed by the backend repository"
  value       = aws_iam_role.github["backend"].arn
}

output "frontend_role_name" {
  description = "Name of the IAM role assumed by the frontend repository"
  value       = aws_iam_role.github["frontend"].name
}

output "frontend_role_arn" {
  description = "ARN of the IAM role assumed by the frontend repository"
  value       = aws_iam_role.github["frontend"].arn
}
