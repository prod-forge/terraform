variable "rds_secrets_arn" {
  description = "RDS Secrets ARN"
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
