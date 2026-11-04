variable "project" {
  description = "Project name, the first part of every resource name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod), the second part of every resource name"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "region" {
  description = "AWS region of the regional provider"
  type        = string
}

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
  description = "Encrypted DB snapshot the RDS instance is created from; null creates an empty database"
  type        = string
  default     = null
}

variable "redis_node_type" {
  type = string
}

variable "redis_snapshot_retention_limit" {
  type = number
}

variable "redis_num_cache_clusters" {
  description = "Redis nodes (primary plus replicas); 1 disables Multi-AZ and automatic failover"
  type        = number
}

variable "vpc_nat_per_az" {
  type = bool
}

variable "vpc_enable_endpoints" {
  type = bool
}

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

variable "domain_name" {
  description = "Web client domain (for example example.com). Empty keeps HTTP on the ALB and the default CloudFront certificate"
  type        = string
  default     = ""
}

variable "hosted_zone_name" {
  description = "Public Route 53 zone for domain_name; defaults to domain_name when empty"
  type        = string
  default     = ""
}

variable "api_subdomain" {
  description = "Subdomain of domain_name that points to the ALB"
  type        = string
  default     = "api"
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to reach Grafana (port 3000). Empty exposes nothing; use SSM port forwarding instead"
  type        = list(string)
  default     = []
}

variable "monitoring_instance_type" {
  description = "EC2 instance type of the monitoring host"
  type        = string
  default     = "t3.small"
}

variable "alert_email" {
  description = "Email that receives CloudWatch alarm and budget notifications; empty disables the subscription and the budget"
  type        = string
  default     = ""
}

variable "monthly_budget_usd" {
  description = "Monthly cost budget in USD; 0 disables the budget"
  type        = number
  default     = 0
}

variable "rds_max_connections_alarm" {
  description = "DatabaseConnections alarm threshold; about 80% of max_connections for the RDS instance class"
  type        = number
  default     = 320
}

variable "app_secret_name" {
  description = "Name of the manually filled backend configuration secret in Secrets Manager"
  type        = string
}

variable "secret_recovery_window_days" {
  description = "Recovery window of every Secrets Manager secret; 0 deletes immediately so a recreated environment can reuse the names"
  type        = number

  validation {
    condition     = var.secret_recovery_window_days == 0 || (var.secret_recovery_window_days >= 7 && var.secret_recovery_window_days <= 30)
    error_message = "secret_recovery_window_days must be 0 or between 7 and 30."
  }
}

variable "create_github_oidc_provider" {
  description = "Create the account-wide GitHub OIDC provider; false reads the existing one (only one may exist per account)"
  type        = bool
}

variable "enable_waf" {
  description = "Attach WAF web ACLs to the ALB and the CloudFront distribution"
  type        = bool
}

variable "enable_client_vpn" {
  description = "Create the Client VPN endpoint; requires the four vpn_* PEM inputs"
  type        = bool
}

variable "vpn_server_certificate" {
  description = "PEM body of the Client VPN server certificate"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vpn_server_private_key" {
  description = "PEM private key of the Client VPN server certificate"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vpn_ca_certificate" {
  description = "PEM body of the CA that signs the server and client certificates"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vpn_ca_private_key" {
  description = "PEM private key of the CA, imported as the client root certificate"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_account_security_services" {
  description = "Create the account-level CloudTrail trail, GuardDuty detector and IAM Access Analyzer; exactly one environment per account owns them"
  type        = bool
}

variable "service_namespace" {
  description = "Cloud Map private DNS namespace; unique per environment so two environments in one account never share a name"
  type        = string
}
