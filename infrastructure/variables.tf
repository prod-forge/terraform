variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "rds_identifier" {
  type = string
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

variable "redis_node_type" {
  type = string
}

variable "redis_snapshot_retention_limit" {
  type = number
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
