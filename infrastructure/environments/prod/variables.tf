############################
# Identity and tags
############################

variable "project" {
  description = "Project name, the first part of every resource name"
  type        = string
}

variable "environment" {
  description = "Environment name, the second part of every resource name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "owner" {
  description = "Owner tag on every resource"
  type        = string
}

variable "cost_center" {
  description = "CostCenter tag on every resource"
  type        = string
}

variable "repository" {
  description = "Repository tag on every resource: where the code that manages it lives"
  type        = string
}

############################
# Account-level and secrets
############################

variable "app_secret_name" {
  description = "Name of the manually filled backend configuration secret"
  type        = string
}

variable "secret_recovery_window_days" {
  description = "Secrets Manager recovery window; 0 deletes immediately"
  type        = number
}

variable "create_github_oidc_provider" {
  description = "Create the account-wide GitHub OIDC provider (false when another environment in the account owns it)"
  type        = bool
}

variable "enable_account_security_services" {
  description = "Create the account-level CloudTrail trail, GuardDuty detector and IAM Access Analyzer (one environment per account)"
  type        = bool
}

############################
# Network
############################

variable "vpc_nat_per_az" {
  type = bool
}

variable "vpc_enable_endpoints" {
  type = bool
}

############################
# RDS
############################

variable "rds_username" {
  type = string
}

variable "rds_db_name" {
  type = string
}

variable "rds_instance_class" {
  type = string
}

variable "rds_multi_az" {
  type = bool
}

variable "rds_backup_retention_period" {
  type = number
}

variable "rds_deletion_protection" {
  type = bool
}

variable "rds_snapshot_identifier" {
  description = "Encrypted DB snapshot the RDS instance is created from (migration or restore); null creates an empty database"
  type        = string
  default     = null
}

variable "rds_max_connections_alarm" {
  description = "DatabaseConnections alarm threshold; about 80% of max_connections for the instance class"
  type        = number
}

############################
# Redis
############################

variable "redis_node_type" {
  type = string
}

variable "redis_num_cache_clusters" {
  type = number
}

variable "redis_snapshot_retention_limit" {
  type = number
}

############################
# ECS
############################

variable "ecs_desired_count" {
  type = number
}

variable "ecs_min_capacity" {
  type = number
}

variable "ecs_max_capacity" {
  type = number
}

variable "ecs_task_cpu" {
  type = number
}

variable "ecs_task_memory" {
  type = number
}

variable "ecs_log_retention_days" {
  type = number
}

############################
# Edge
############################

variable "domain_name" {
  description = "Web client domain; empty keeps HTTP on the ALB and the default CloudFront certificate"
  type        = string
}

variable "hosted_zone_name" {
  description = "Public Route 53 zone for domain_name; empty defaults to domain_name"
  type        = string
}

variable "api_subdomain" {
  type = string
}

variable "enable_waf" {
  type = bool
}

############################
# Client VPN
############################

variable "enable_client_vpn" {
  description = "Create the Client VPN endpoint from the key files in vpn_key_dir"
  type        = bool

  # Fail the plan instead of creating or keeping a VPN without its key material.
  validation {
    condition     = !var.enable_client_vpn || alltrue([for pem in values(local.vpn_pem) : pem != ""])
    error_message = "enable_client_vpn needs server.crt, server.key, ca.crt and ca.key in vpn_key_dir."
  }
}

variable "vpn_key_dir" {
  description = "Directory with server.crt, server.key, ca.crt and ca.key, relative to this root"
  type        = string
  default     = "../../vpn-key"
}

############################
# Monitoring and alerts
############################

variable "monitoring_instance_type" {
  type = string
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to reach Grafana; empty exposes nothing"
  type        = list(string)
}

variable "alert_email" {
  description = "Alarm and budget notification email; empty disables the subscription and the budget"
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly cost budget in USD; 0 disables the budget"
  type        = number
}
