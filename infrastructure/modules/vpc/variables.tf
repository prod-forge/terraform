variable "project" {
  description = "Project name used to prefix resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod) used to prefix resource names"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "az_count must be at least 2 (RDS subnet groups and the ALB need two AZs)."
  }
}

variable "nat_per_az" {
  description = "Create one NAT gateway per AZ (true) or a single shared NAT gateway (false)"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Create interface endpoints for ECR, Secrets Manager, CloudWatch Logs and SSM messages"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "CloudWatch retention for VPC flow logs"
  type        = number
  default     = 30
}
