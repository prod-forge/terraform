output "repository_url" {
  value = aws_ecr_repository.prod_forge_repo.repository_url
}

output "repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.prod_forge_repo.name
}
