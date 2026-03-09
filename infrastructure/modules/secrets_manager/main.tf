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
