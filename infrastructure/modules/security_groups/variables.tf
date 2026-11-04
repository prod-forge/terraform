variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block, the only source allowed into the Client VPN security group"
  type        = string
}

variable "project" {
  description = "Project name used to prefix security group names"
  type        = string
}
