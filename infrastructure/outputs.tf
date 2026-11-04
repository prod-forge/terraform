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
