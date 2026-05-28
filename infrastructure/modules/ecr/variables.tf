variable "repository_name" {
  description = "ECR Name"
  type        = string
}

variable "github_actions_role_name" {
  description = "IAM role name for GitHub Actions to attach ECR deploy policy"
  type        = string
}
