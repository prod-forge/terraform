############################################################
# GitHub OIDC Provider
############################################################

# AWS validates the GitHub certificate chain with its trusted CA library and
# ignores thumbprint_list for token.actions.githubusercontent.com, so none is set.
# Only one provider per URL may exist in an account: the environment that owns
# it creates it, the others in the same account read it.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

moved {
  from = aws_iam_openid_connect_provider.github
  to   = aws_iam_openid_connect_provider.github[0]
}

############################################################
# IAM Roles for GitHub Actions
############################################################

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn

  roles = {
    backend  = var.backend_repo
    frontend = var.frontend_repo
  }
}

# Each role trusts only jobs of its own repository that run in the GitHub
# environment (sub: repo:<owner>/<repo>:environment:<env>). No ref-based subject
# is trusted, so the environment protection rules always gate the deploy.
resource "aws_iam_role" "github" {
  for_each = local.roles

  name = "${var.project}-${var.environment}-github-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_owner}/${each.value}:environment:${var.github_environment}"
          }
        }
      }
    ]
  })
}
