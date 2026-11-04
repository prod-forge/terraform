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

variable "recovery_window_in_days" {
  description = "Days a deleted secret stays recoverable; 0 deletes immediately so a recreated environment can reuse the names"
  type        = number
  default     = 30
}
