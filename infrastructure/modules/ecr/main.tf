############################################################
# ECR Repository
############################################################

resource "aws_ecr_repository" "prod_forge_repo" {
  name                 = var.repository_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Changing the encryption type forces a new repository; see guide/workflow.md.
  encryption_configuration {
    encryption_type = "KMS"
  }
}

############################################################
# ECR Lifecycle Policy
############################################################

############################
# Keep 3 the latest images + : initial
############################

resource "aws_ecr_lifecycle_policy" "prod_forge_repo_policy" {
  repository = aws_ecr_repository.prod_forge_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Exclude :initial version from removing"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["initial"]
          countType     = "imageCountMoreThan"
          countNumber   = 9999
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 3 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 3
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

############################################################
# GitHub Actions ECR Permissions
############################################################

resource "aws_iam_policy" "ecr_deploy" {
  name = "${var.repository_name}-github-ecr-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # GetAuthorizationToken does not support resource-level permissions.
        Sid      = "AuthToken"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "PushImage"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
        ]
        Resource = aws_ecr_repository.prod_forge_repo.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_deploy" {
  role       = var.backend_role_name
  policy_arn = aws_iam_policy.ecr_deploy.arn
}
