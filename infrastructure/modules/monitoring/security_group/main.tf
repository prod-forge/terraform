# name_prefix and create_before_destroy let a replacement group attach to the
# instance before the old one is deleted.
resource "aws_security_group" "monitoring" {
  #checkov:skip=CKV2_AWS_5: attached to the monitoring instance in module.monitoring_ec2; Checkov does not follow the id across modules
  name_prefix = "${var.project}-${var.environment}-monitoring-sg-"
  description = "Monitoring host: Grafana from the admin CIDR blocks, outbound for packages, images and AWS APIs"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.monitoring_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    description = "Outbound for packages, container images and AWS APIs"
    from_port   = var.monitoring_egress_from_port
    to_port     = var.monitoring_egress_to_port
    protocol    = var.monitoring_egress_protocol
    cidr_blocks = var.monitoring_egress_cidr_blocks
  }

  lifecycle {
    create_before_destroy = true
  }
}
