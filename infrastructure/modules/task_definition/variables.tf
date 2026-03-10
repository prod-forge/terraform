variable "repository_url" {
  description = "Repository URL"
  type        = string
}

variable "task_execution_role_arn" {
  description = "IAM Task Execution Role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "IAM Task Role ARN"
  type        = string
}

variable "rds_secrets_arn" {
  description = "RDS Secrets ARN"
  type        = string
}

variable "db_name" {
  description = "DB Table Name"
  type        = string
}

variable "db_username" {
  description = "DB Username"
  type        = string
}

variable "db_host" {
  description = "DB Host"
  type        = string
}

variable "db_port" {
  description = "DB Port"
  type        = string
}

variable "redis_host" {
  description = "Redis Host"
  type        = string
}

variable "redis_port" {
  description = "Redis Port"
  type        = string
}

variable "project" {
  description = "Project Name"
  type        = string
}
