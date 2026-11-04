variable "project" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "bucket_name" {
  description = "Name of the access-log bucket shared by the ALB and CloudFront"
  type        = string
}

variable "retention_days" {
  description = "Days to keep access logs before expiry"
  type        = number
  default     = 90
}

variable "alb_prefix" {
  description = "Key prefix for ALB access logs"
  type        = string
  default     = "alb"
}

variable "cloudfront_prefix" {
  description = "Key prefix for CloudFront standard logs"
  type        = string
  default     = "cloudfront"
}
