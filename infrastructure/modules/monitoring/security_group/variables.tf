variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "monitoring_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "monitoring_egress_from_port" {
  description = "Start port for egress traffic"
  type        = number
}

variable "monitoring_egress_to_port" {
  description = "End port for egress traffic"
  type        = number
}

variable "monitoring_egress_protocol" {
  description = "Protocol for egress traffic"
  type        = string
}

variable "monitoring_egress_cidr_blocks" {
  description = "CIDR blocks for egress traffic"
  type        = list(string)
}
