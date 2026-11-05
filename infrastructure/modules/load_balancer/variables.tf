variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "sg_alb_id" {
  description = "Security Group for Load Balancer ID"
  type        = string
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs"
}

variable "project" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Environment name; deletion protection is enabled only for prod"
  type        = string
}

variable "domain_name" {
  description = "API domain (for example api.example.com). Empty disables the 443 listener and the HTTP to HTTPS redirect"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "Validated ACM certificate for domain_name; required when domain_name is set"
  type        = string
  default     = ""

  validation {
    condition     = var.domain_name == "" || var.certificate_arn != ""
    error_message = "certificate_arn is required when domain_name is set."
  }
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
}

variable "access_logs_prefix" {
  description = "Key prefix for ALB access logs"
  type        = string
  default     = "alb"
}

variable "app_port" {
  description = "Port the backend container listens on"
  type        = number
  default     = 3000
}
