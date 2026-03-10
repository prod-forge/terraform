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
