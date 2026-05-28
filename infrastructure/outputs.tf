output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "github_actions_role_arn" {
  value = module.github_oidc.github_actions_role_arn
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
