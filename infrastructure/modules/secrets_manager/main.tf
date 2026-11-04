############################
# AWS KMS - Encryption for Secrets Manager
############################
resource "aws_kms_key" "this" {
  description = "KMS key for app secrets"
}

############################
# AWS Secrets Manager - Manual secrets creation
############################
resource "aws_secretsmanager_secret" "prod_forge_secret" {
  name       = var.secrets_manager_name
  kms_key_id = aws_kms_key.this.arn
}

############################
# Generated secrets
############################
resource "random_password" "redis" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "redis_auth" {
  name       = "${var.project}/${var.environment}/redis-auth"
  kms_key_id = aws_kms_key.this.arn
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = random_password.redis.result
}

resource "random_password" "jwt" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "jwt" {
  name       = "${var.project}/${var.environment}/jwt-secret"
  kms_key_id = aws_kms_key.this.arn
}

resource "aws_secretsmanager_secret_version" "jwt" {
  secret_id     = aws_secretsmanager_secret.jwt.id
  secret_string = random_password.jwt.result
}

resource "random_password" "grafana_admin" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "grafana_admin" {
  name       = "${var.project}/${var.environment}/grafana-admin"
  kms_key_id = aws_kms_key.this.arn
}

resource "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id     = aws_secretsmanager_secret.grafana_admin.id
  secret_string = random_password.grafana_admin.result
}
