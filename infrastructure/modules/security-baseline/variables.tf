variable "project" {
  description = "Project name, used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod), used in resource names"
  type        = string
}

variable "enable_cloudtrail" {
  description = "Create the multi-region CloudTrail trail with its encrypted bucket and SNS topic"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Create the GuardDuty detector; only one may exist per account and region"
  type        = bool
  default     = true
}

variable "enable_access_analyzer" {
  description = "Create an account-level IAM Access Analyzer"
  type        = bool
  default     = true
}

variable "cloudtrail_archive_after_days" {
  description = "Days after which trail log files move to Glacier Instant Retrieval"
  type        = number
  default     = 90
}

variable "cloudtrail_retention_days" {
  description = "Days to keep trail log files before expiry"
  type        = number
  default     = 365

  validation {
    condition     = var.cloudtrail_retention_days > var.cloudtrail_archive_after_days
    error_message = "cloudtrail_retention_days must be greater than cloudtrail_archive_after_days."
  }
}
