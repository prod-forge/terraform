variable "db_subnet_group_name" {
  description = "DB Subnet Group Name"
  type        = string
}

variable "vpc_security_group_id" {
  description = "VPC Security Group ID"
  type        = string
}

variable "username" {
  description = "DB Username"
  type        = string
}

variable "db_name" {
  description = "DB Name"
  type        = string
}

variable "rds_identifier" {
  description = "RDS Identifier"
  type        = string
}




variable "project" {
  description = "Project name, used in the final snapshot identifier"
  type        = string
}

variable "environment" {
  description = "Environment name, used in the final snapshot identifier"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for storage, Performance Insights and the master user secret"
  type        = string
}

variable "multi_az" {
  description = "Deploy a standby in a second Availability Zone"
  type        = bool
  default     = false
}

variable "instance_class" {
  description = "DB instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GiB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Storage autoscaling limit in GiB"
  type        = number
  default     = 100
}

variable "backup_retention_period" {
  description = "Automated backup retention in days (PITR window)"
  type        = number
  default     = 1
}

variable "backup_window" {
  description = "Daily UTC backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly UTC maintenance window"
  type        = string
  default     = "sun:04:30-sun:05:30"
}

variable "deletion_protection" {
  description = "Block deletion of the instance"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of in the maintenance window"
  type        = bool
  default     = false
}
