resource "aws_cloudwatch_log_group" "connections" {
  #checkov:skip=CKV_AWS_158: encrypted at rest with the CloudWatch Logs service key; a dedicated CMK for logs is not provisioned yet
  #checkov:skip=CKV_AWS_338: connection logs are kept for access audits; retention is set by var.connection_log_retention_days to bound cost
  name              = "/vpn/${var.project}-${var.environment}-client-vpn"
  retention_in_days = var.connection_log_retention_days
}

resource "aws_cloudwatch_log_stream" "connections" {
  name           = "connections"
  log_group_name = aws_cloudwatch_log_group.connections.name
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "${var.project}-${var.environment}-client-vpn"
  server_certificate_arn = var.server_vpn_certificate_arn
  client_cidr_block      = var.client_cidr_block
  # The Amazon-provided DNS server sits at the VPC base address plus two.
  dns_servers = [cidrhost(var.vpc_cidr, 2)]

  # Only the VPC CIDR is authorised, so only VPC traffic goes through the tunnel.
  split_tunnel = true

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_vpn_certificate_arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.connections.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.connections.name
  }

  security_group_ids = [var.sg_vpn_id]

  vpc_id = var.vpc_main_id
}

output "id" {
  value = aws_ec2_client_vpn_endpoint.vpn.id
}
