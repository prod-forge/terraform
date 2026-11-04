variable "project" {
  description = "Project name, used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod), used in resource names"
  type        = string
}

variable "private_key" {
  description = "PEM private key"
  type        = string
  sensitive   = true
}

variable "certificate_body" {
  description = "PEM certificate body"
  type        = string
  sensitive   = true
}

variable "certificate_chain" {
  description = "PEM certificate chain"
  type        = string
  sensitive   = true
}
