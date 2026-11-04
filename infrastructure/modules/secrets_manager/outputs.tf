output "secret_arn" {
  description = "Secrets Manager ARN"
  value       = aws_secretsmanager_secret.prod_forge_secret.arn
}
output "kms_arn" {
  description = "KMS ARN"
  value       = aws_kms_key.this.arn
}


output "redis_auth_token" {
  description = "Redis AUTH token"
  value       = random_password.redis.result
  sensitive   = true
}

output "redis_auth_secret_arn" {
  description = "Redis AUTH token secret ARN"
  value       = aws_secretsmanager_secret.redis_auth.arn
}

output "jwt_secret_arn" {
  description = "JWT signing secret ARN"
  value       = aws_secretsmanager_secret.jwt.arn
}
