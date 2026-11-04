variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "web_client_bucket_name" {
  type = string
}

variable "assets_bucket_name" {
  type = string
}

variable "frontend_role_name" {
  description = "Frontend GitHub Actions role that receives the deploy policy"
  type        = string
}

variable "domain_name" {
  description = "Custom domain for the distribution. Empty keeps the default *.cloudfront.net certificate"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "Validated us-east-1 ACM certificate for domain_name; required when domain_name is set"
  type        = string
  default     = ""

  validation {
    condition     = var.domain_name == "" || var.acm_certificate_arn != ""
    error_message = "acm_certificate_arn is required when domain_name is set."
  }
}

variable "web_acl_arn" {
  description = "ARN of the CLOUDFRONT-scope WAF web ACL"
  type        = string
}

variable "logs_bucket_domain_name" {
  description = "Domain name of the S3 bucket for CloudFront standard logs"
  type        = string
}

variable "logs_prefix" {
  description = "Key prefix for CloudFront standard logs"
  type        = string
  default     = "cloudfront"
}

variable "noncurrent_version_expiration_days" {
  description = "Days to keep previous web client builds"
  type        = number
  default     = 30
}
