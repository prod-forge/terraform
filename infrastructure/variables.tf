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
