variable "project" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "alert_email" {
  description = "Email that receives alarm and budget notifications; empty creates no subscription and no budget"
  type        = string
  default     = ""
}

variable "monthly_budget_usd" {
  description = "Monthly cost budget in USD; 0 disables the budget"
  type        = number
  default     = 0

  validation {
    condition     = var.monthly_budget_usd >= 0
    error_message = "monthly_budget_usd must not be negative."
  }
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

variable "lb_arn_suffix" {
  description = "ALB ARN suffix (CloudWatch LoadBalancer dimension)"
  type        = string
}

variable "lb_target_group_arn_suffix" {
  description = "Target group ARN suffix (CloudWatch TargetGroup dimension)"
  type        = string
}

variable "rds_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "rds_max_connections_alarm" {
  description = "DatabaseConnections threshold; about 80% of max_connections for the instance class (320 for db.t4g.medium)"
  type        = number
  default     = 320
}

variable "redis_replication_group_id" {
  description = "ElastiCache replication group ID"
  type        = string
}

variable "redis_num_cache_clusters" {
  description = "Number of Redis nodes; one alarm per node and metric"
  type        = number
}

variable "nat_gateway_ids" {
  description = "NAT gateway IDs; one alarm per gateway"
  type        = list(string)
}
