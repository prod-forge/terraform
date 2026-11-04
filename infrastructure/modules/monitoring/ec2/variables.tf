variable "repository_url" {
  description = "ECR URL"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type of the monitoring host"
  type        = string
  default     = "t3.small"
}

variable "sg_monitoring_id" {
  description = "Security Group Monitoring ID"
  type        = string
}

variable "monitoring_ec2_instance_profile_name" {
  description = "IAM Monitoring Instance Profile Name"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID"
  type        = string
}

variable "secret_id" {
  description = "Secrets Manager secret ARN or name for the monitoring EC2"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "observability_bucket" {
  description = "S3 bucket holding the observability stack configuration"
  type        = string
}

variable "grafana_admin_secret_arn" {
  description = "Secrets Manager ARN of the Grafana admin password"
  type        = string
}
