variable "repository_name" {
  description = "ECR Name"
  type        = string
}

variable "backend_role_name" {
  description = "Backend GitHub Actions role that receives the ECR push policy"
  type        = string
}
