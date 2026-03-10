resource "aws_acm_certificate" "vpn_server" {
  private_key       = var.private_key
  certificate_body  = var.certificate_body
  certificate_chain = var.certificate_chain
  tags = {
    Name = "server-vpn-cert"
  }
}
