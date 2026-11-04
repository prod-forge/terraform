resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "${var.project}.local"
  description = "Private service discovery for ${var.project}"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.this.id
    routing_policy = "MULTIVALUE"

    dns_records {
      type = "A"
      ttl  = 10
    }
  }

  # ECS reports task health to Cloud Map through this custom health check.
  health_check_custom_config {}
}
