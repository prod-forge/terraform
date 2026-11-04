variable "domain_name" {
  description = "Web client domain served by CloudFront. Empty disables every record in this module"
  type        = string
  default     = ""
}

variable "hosted_zone_name" {
  description = "Public Route 53 hosted zone that contains domain_name"
  type        = string
  default     = ""

  validation {
    condition     = var.domain_name == "" || var.hosted_zone_name != ""
    error_message = "hosted_zone_name is required when domain_name is set."
  }
}

variable "api_domain_name" {
  description = "API domain that points to the ALB"
  type        = string
  default     = ""
}

variable "alb_dns_name" {
  description = "ALB DNS name"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB canonical hosted zone ID"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  type        = string
}

variable "cloudfront_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  type        = string
}
