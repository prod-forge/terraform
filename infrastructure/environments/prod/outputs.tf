output "ecr_repository_url" {
  value = module.stack.ecr_repository_url
}

output "github_backend_role_arn" {
  value = module.stack.github_backend_role_arn
}

output "github_frontend_role_arn" {
  value = module.stack.github_frontend_role_arn
}

output "web_client_bucket_name" {
  value = module.stack.web_client_bucket_name
}

output "cloudfront_distribution_id" {
  value = module.stack.cloudfront_distribution_id
}

output "cloudfront_url" {
  value = module.stack.cloudfront_url
}

output "assets_bucket_name" {
  value = module.stack.assets_bucket_name
}

output "api_url" {
  description = "Public API base URL"
  value       = module.stack.api_url
}

output "ecr_repository_name" {
  value = module.stack.ecr_repository_name
}

output "ecs_cluster_name" {
  value = module.stack.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.stack.ecs_service_name
}

output "ecs_task_definition_family" {
  value = module.stack.ecs_task_definition_family
}

output "ecs_migration_task_definition_family" {
  value = module.stack.ecs_migration_task_definition_family
}

output "ecs_log_group_name" {
  value = module.stack.ecs_log_group_name
}

output "ecs_migration_log_group_name" {
  value = module.stack.ecs_migration_log_group_name
}

output "private_subnet_ids" {
  value = module.stack.private_subnet_ids
}

output "ecs_security_group_id" {
  value = module.stack.ecs_security_group_id
}
