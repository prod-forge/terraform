############################
# Current user data
############################

data "aws_caller_identity" "current" {}

############################
# Github OIDC
############################

module "github_oidc" {
  source         = "./modules/github-oidc"
  github_owner   = "prod-forge"
  github_repo    = "backend"
  aws_account_id = data.aws_caller_identity.current.account_id
}

############################
# Secrets manager
############################

module "secrets_manager" {
  secrets_manager_name = "prod_forge/backend/config-v1"
  source = "./modules/secrets_manager"
}

############################
# ECR
############################

module "ecr" {
  source          = "./modules/ecr"
  repository_name = var.project
}
