variable "domain_name" {
  description = "Domain the certificate is issued for. Empty creates nothing"
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route 53 zone ID for the DNS validation record; required when domain_name is set"
  type        = string
  default     = ""

  validation {
    condition     = var.domain_name == "" || var.hosted_zone_id != ""
    error_message = "hosted_zone_id is required when domain_name is set."
  }
}
