variable "project" {
  description = "Project name, used in the bucket name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "source_dir" {
  description = "Directory holding the observability stack files uploaded to the bucket"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used for server-side encryption of the bucket"
  type        = string
}

variable "service_namespace" {
  description = "Cloud Map namespace the backend registers in; Prometheus scrapes backend.<namespace>"
  type        = string
}

variable "app_port" {
  description = "Port the backend container listens on"
  type        = number
  default     = 3000
}
