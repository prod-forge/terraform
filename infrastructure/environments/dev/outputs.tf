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
