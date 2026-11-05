variable "project" {
  description = "Project name, used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod), used in resource names"
  type        = string
}

variable "server_vpn_certificate_arn" {
  description = "Server VPN Certificate ARN"
  type        = string
}

variable "client_vpn_certificate_arn" {
  description = "Client VPN Certificate ARN"
  type        = string
}

variable "sg_vpn_id" {
  description = "Security Group VPN ID"
  type        = string
}

variable "vpc_main_id" {
  description = "VPC Main ID"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC; the VPN pushes its Amazon-provided DNS server (base address plus two)"
  type        = string
}

variable "client_cidr_block" {
  description = "CIDR block that VPN client addresses are assigned from; must not overlap the VPC CIDR"
  type        = string
  default     = "10.200.0.0/22"
}

variable "connection_log_retention_days" {
  description = "Days to keep the Client VPN connection logs"
  type        = number
  default     = 30
}
