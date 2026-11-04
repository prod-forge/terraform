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

variable "redis_auth_secret_arn" {
  description = "Redis AUTH token secret ARN"
  type        = string
}

variable "jwt_secret_arn" {
  description = "JWT signing secret ARN"
  type        = string
}

variable "region" {
  description = "AWS region for the awslogs driver"
  type        = string
}

variable "image_tag" {
  description = "Image tag of the initial task definition revision; also exposed as APP_VERSION"
  type        = string
  default     = "initial"
}

variable "cpu" {
  description = "Task CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory (MiB)"
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "CloudWatch retention for application and migration logs"
  type        = number
  default     = 7
}
