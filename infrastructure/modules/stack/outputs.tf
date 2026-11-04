output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "github_backend_role_arn" {
  value = module.github_oidc.backend_role_arn
}

output "github_frontend_role_arn" {
  value = module.github_oidc.frontend_role_arn
}

output "web_client_bucket_name" {
  value = module.frontend.web_client_bucket_name
}

output "cloudfront_distribution_id" {
  value = module.frontend.cloudfront_distribution_id
}

output "cloudfront_url" {
  value = module.frontend.cloudfront_url
}

output "assets_bucket_name" {
  value = module.frontend.assets_bucket_name
}

output "api_url" {
  description = "Public API base URL: HTTPS on the API domain when domain_name is set, otherwise plain HTTP on the ALB"
  value       = local.api_domain_name != "" ? "https://${local.api_domain_name}" : "http://${module.load_balancer.lb_dns_name}"
}

# Names and network ids that backend CD reads from GitHub repository variables (docs/workflow.md).

output "ecr_repository_name" {
  description = "ECR repository the backend image is pushed to"
  value       = module.ecr.repository_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs_cluster.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs_service.service_name
}

output "ecs_task_definition_family" {
  description = "Task definition family of the application"
  value       = module.task_definition.task_definition_family
}

output "ecs_migration_task_definition_family" {
  description = "Task definition family of the one-off migration task registered by backend CD"
  value       = local.migration_task_definition_family
}

output "ecs_log_group_name" {
  description = "CloudWatch log group of the application task"
  value       = module.task_definition.log_group_name
}

output "ecs_migration_log_group_name" {
  description = "CloudWatch log group of the migration task"
  value       = module.task_definition.migration_log_group_name
}

output "private_subnet_ids" {
  description = "Private subnets the ECS service and the migration task run in"
  value       = module.vpc.private_subnet_ids
}

output "ecs_security_group_id" {
  description = "Security group of the ECS service, reused by the migration task"
  value       = module.security_groups.sg_ecs_id
}
