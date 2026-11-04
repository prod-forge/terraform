variable "project" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "scope" {
  description = "REGIONAL (ALB) or CLOUDFRONT (requires a us-east-1 provider)"
  type        = string

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "resource_arn" {
  description = "ARN of the regional resource (ALB) to associate; required for REGIONAL scope"
  type        = string
  default     = ""

  validation {
    condition     = var.scope != "REGIONAL" || var.resource_arn != ""
    error_message = "resource_arn is required for REGIONAL scope."
  }
}

variable "rate_limit" {
  description = "Maximum requests per client IP in a 5-minute window before WAF blocks it"
  type        = number
  default     = 2000
}
