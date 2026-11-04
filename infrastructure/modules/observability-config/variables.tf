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
