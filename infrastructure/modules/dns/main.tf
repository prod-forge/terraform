locals {
  enabled = var.domain_name != ""
}

data "aws_route53_zone" "this" {
  count = local.enabled ? 1 : 0

  name         = var.hosted_zone_name
  private_zone = false
}

# The ALB is IPv4-only (the VPC has no IPv6 CIDR), so the API gets an A record only.
resource "aws_route53_record" "api" {
  count = local.enabled ? 1 : 0

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = var.api_domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "web" {
  for_each = local.enabled ? toset(["A", "AAAA"]) : toset([])

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = var.domain_name
  type    = each.key

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_zone_id
    evaluate_target_health = false
  }
}
