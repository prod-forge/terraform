resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "client-vpn"
  server_certificate_arn = var.server_vpn_certificate_arn
  client_cidr_block      = "10.200.0.0/22"
  dns_servers            = ["10.0.0.2"]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_vpn_certificate_arn
  }

  connection_log_options {
    enabled = false
  }

  security_group_ids = [var.sg_vpn_id]

  vpc_id = var.vpc_main_id
}

output "id" {
  value = aws_ec2_client_vpn_endpoint.vpn.id
}
