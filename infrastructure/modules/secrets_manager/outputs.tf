output "secret_arn" {
  description = "Secrets Manager ARN"
  value       = aws_secretsmanager_secret.prod_forge_secret.arn
}
output "kms_arn" {
  description = "KMS ARN"
  value       = aws_kms_key.this.arn
}

