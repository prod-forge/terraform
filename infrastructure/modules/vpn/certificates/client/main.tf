resource "aws_acm_certificate" "vpn_client" {
  private_key      = var.private_key
  certificate_body = var.certificate_body

  tags = {
    Name = "client-vpn-ca"
  }
}
