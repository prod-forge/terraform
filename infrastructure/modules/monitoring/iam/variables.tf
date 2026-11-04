variable "project" {
  description = "Project name, used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod), used in resource names"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS Key ARN"
  type        = string
}

variable "grafana_admin_secret_arn" {
  description = "Secrets Manager ARN of the Grafana admin credentials; empty grants no access"
  type        = string
  default     = ""
}

variable "observability_config_bucket_arn" {
  description = "S3 bucket ARN holding the observability stack configuration"
  type        = string
}
