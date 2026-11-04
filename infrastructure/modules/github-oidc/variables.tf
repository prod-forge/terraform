variable "project" {
  description = "Project name used in role names"
  type        = string
}

variable "environment" {
  description = "Deployment environment used in role names"
  type        = string
}

variable "github_owner" {
  description = "GitHub organization or user"
  type        = string
}

variable "backend_repo" {
  description = "Repository allowed to assume the backend role"
  type        = string
  default     = "backend"
}

variable "frontend_repo" {
  description = "Repository allowed to assume the frontend role"
  type        = string
  default     = "frontend"
}

variable "github_environment" {
  description = "GitHub environment name that deploy jobs run in"
  type        = string
  default     = "prod"
}
