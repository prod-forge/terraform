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
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_owner}/${var.github_repo}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_passrole_policy" {
  name = "github-actions-ecs-passrole-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = [
          "arn:aws:iam::${var.aws_account_id}:role/ecs-task-role",
          "arn:aws:iam::${var.aws_account_id}:role/ecs-task-execution-role"
        ]
      }
    ]
  })
}

############################################################
# ECR Permissions
############################################################

resource "aws_iam_policy" "ecr_policy" {
  name = "github-actions-ecr-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories"
        ]
        Resource = "*"
      }
    ]
  })
}

############################################################
# ECS Permissions
############################################################

resource "aws_iam_policy" "ecs_policy" {
  name = "github-actions-ecs-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "ecs:DeregisterTaskDefinition",
          "ecs:DescribeClusters",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:ListTaskDefinitions",
          "ecs:TagResource",
          "rds:DescribeDBInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

############################################################
# Attach Policies to Role
############################################################

resource "aws_iam_role_policy_attachment" "attach_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_ecs" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecs_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_ecs_passrole" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecs_passrole_policy.arn
}
