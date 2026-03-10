resource "aws_ec2_client_vpn_authorization_rule" "allow_vpc" {
  client_vpn_endpoint_id = var.vpn_endpoint_id
  target_network_cidr    = var.vpc_cidr
  authorize_all_groups   = true
}
