resource "aws_acm_certificate" "vpn_client" {
  private_key      = var.private_key
  certificate_body = var.certificate_body

  tags = {
    Name = "${var.project}-${var.environment}-client-vpn-ca"
  }

  lifecycle {
    create_before_destroy = true
  }
}
