############################################################
# GitHub OIDC Provider
############################################################

# AWS validates the GitHub certificate chain with its trusted CA library and
# ignores thumbprint_list for token.actions.githubusercontent.com, so none is set.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

############################################################
# IAM Roles for GitHub Actions
############################################################

locals {
  roles = {
    backend  = var.backend_repo
    frontend = var.frontend_repo
  }
}

# Each role trusts only its own repository: jobs that run in the GitHub
# environment (sub: repo:<owner>/<repo>:environment:<env>) and release tags.
# A job that declares `environment:` gets the environment sub claim instead of
# the ref claim, so the protection rules of the environment gate the deploy.
resource "aws_iam_role" "github" {
  for_each = local.roles

  name = "${var.project}-${var.environment}-github-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # StringLike only because the tag pattern needs a wildcard.
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_owner}/${each.value}:environment:${var.github_environment}",
              "repo:${var.github_owner}/${each.value}:ref:refs/tags/v*",
            ]
          }
        }
      }
    ]
  })
}
