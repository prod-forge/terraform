variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block: the only source allowed into the Client VPN group and the only egress target of the ALB and VPN groups"
  type        = string
}

variable "project" {
  description = "Project name used to prefix security group names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod), used to prefix security group names"
  type        = string
}

variable "app_port" {
  description = "Port the backend container listens on"
  type        = number
  default     = 3000
}
