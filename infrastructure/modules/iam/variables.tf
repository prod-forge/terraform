variable "project" {
  description = "Project name, used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod), used in resource names"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the RDS-managed master user secret"
  type        = string
}

variable "kms_arn" {
  description = "KMS ARN"
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

variable "app_secret_arn" {
  description = "Manually filled application config secret ARN (SENTRY_DSN)"
  type        = string
}
