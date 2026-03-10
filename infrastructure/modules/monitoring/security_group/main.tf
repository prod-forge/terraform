resource "aws_security_group" "monitoring" {
  name   = "monitoring-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.monitoring_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = var.monitoring_egress_from_port
    to_port     = var.monitoring_egress_to_port
    protocol    = var.monitoring_egress_protocol
    cidr_blocks = var.monitoring_egress_cidr_blocks
  }
}
