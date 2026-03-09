resource "aws_ecr_repository" "prod_forge_repo" {
  name = var.repository_name
}

############################
# ECR Policy
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
