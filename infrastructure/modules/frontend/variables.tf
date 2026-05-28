variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "web_client_bucket_name" {
  type = string
}

variable "assets_bucket_name" {
  type = string
}

variable "github_actions_role_name" {
  description = "IAM role name for GitHub Actions to attach deploy policy"
  type        = string
}
