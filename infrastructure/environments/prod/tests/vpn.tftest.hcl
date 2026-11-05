# Offline plan-only tests for the Client VPN endpoint. The run targets the
# module directly: the stack creates it only with the git-ignored key files.

mock_provider "aws" {}

variables {
  project     = "prod-forge-test"
  environment = "prod"

  server_vpn_certificate_arn = "arn:aws:acm:eu-central-1:123456789012:certificate/00000000-0000-0000-0000-000000000001"
  client_vpn_certificate_arn = "arn:aws:acm:eu-central-1:123456789012:certificate/00000000-0000-0000-0000-000000000002"
  sg_vpn_id                  = "sg-0123456789abcdef0"
  vpc_main_id                = "vpc-0123456789abcdef0"
}

############################
# Positive cases
############################

run "endpoint_uses_the_vpc_dns_server_and_split_tunnel" {
  command = plan

  module {
    source = "../../modules/vpn/vpn-endpoint"
  }

  variables {
    vpc_cidr = "10.10.0.0/16"
  }

  assert {
    condition     = aws_ec2_client_vpn_endpoint.vpn.dns_servers == tolist(["10.10.0.2"])
    error_message = "The VPN must push the Amazon-provided DNS server of the VPC (base address plus two)."
  }

  assert {
    condition     = aws_ec2_client_vpn_endpoint.vpn.client_cidr_block == "10.200.0.0/22"
    error_message = "Client addresses must come from 10.200.0.0/22 by default."
  }

  assert {
    condition     = aws_ec2_client_vpn_endpoint.vpn.split_tunnel
    error_message = "Only VPC traffic may go through the tunnel."
  }

  assert {
    condition = (
      aws_ec2_client_vpn_endpoint.vpn.connection_log_options[0].enabled &&
      aws_cloudwatch_log_group.connections.name == "/vpn/prod-forge-test-prod-client-vpn" &&
      aws_cloudwatch_log_group.connections.retention_in_days == 30
    )
    error_message = "Connection logs must go to the project log group for 30 days."
  }
}
