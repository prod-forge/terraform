output "certificate_arn" {
  description = "ARN of the validated certificate, empty when domain_name is empty"
  value       = local.enabled ? aws_acm_certificate_validation.this[0].certificate_arn : ""
}
