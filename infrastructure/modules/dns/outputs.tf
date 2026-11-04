output "zone_id" {
  description = "Hosted zone ID, empty when no domain is configured"
  value       = local.enabled ? data.aws_route53_zone.this[0].zone_id : ""
}
