variable "sg_redis_id" {
  description = "SG Redis ID"
  type        = string
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "project" {
  description = "Project Name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for at-rest encryption"
  type        = string
}

variable "auth_token" {
  description = "Redis AUTH token"
  type        = string
  sensitive   = true
}

variable "node_type" {
  description = "Cache node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "num_cache_clusters" {
  description = "Number of nodes (primary plus replicas); 2 or more enables Multi-AZ and automatic failover"
  type        = number
  default     = 2

  validation {
    condition     = var.num_cache_clusters >= 1 && var.num_cache_clusters <= 6
    error_message = "num_cache_clusters must be between 1 and 6."
  }
}

variable "snapshot_retention_limit" {
  description = "Days to keep automatic snapshots"
  type        = number
  default     = 1
}

variable "snapshot_window" {
  description = "Daily snapshot window (UTC)"
  type        = string
  default     = "02:00-03:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of in the maintenance window"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Environment name (dev, prod), used in resource names"
  type        = string
}
