resource "aws_ec2_client_vpn_network_association" "vpn_assoc" {
  client_vpn_endpoint_id = var.vpn_endpoint_id
  subnet_id              = var.subnet_id
}
