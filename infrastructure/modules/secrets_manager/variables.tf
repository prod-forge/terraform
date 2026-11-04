variable "secrets_manager_name" {
  description = "Secrets Manager Name"
  type        = string
}

variable "project" {
  description = "Project name, used in generated secret names"
  type        = string
}

variable "environment" {
  description = "Environment name, used in generated secret names"
  type        = string
}
