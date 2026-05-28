############################################################
# GitHub OIDC Provider
############################################################

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    # GitHub OIDC SHA1 thumbprint
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

############################################################
# IAM Role for GitHub Actions
############################################################

resource "aws_iam_role" "github_actions" {
  name = "github-actions-ecs-ecr-role"

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
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [for repo in var.github_repos : "repo:${var.github_owner}/${repo}:*"]
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

