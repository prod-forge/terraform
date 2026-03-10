variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "sg_alb_id" {
  description = "Security Group for Load Balancer ID"
  type        = string
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs"
}

variable "project" {
  description = "Project Name"
  type        = string
}
