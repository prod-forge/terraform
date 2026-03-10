output "secrets_arn" {
  value = aws_db_instance.postgres.master_user_secret[0].secret_arn
}

output "port" {
  value = aws_db_instance.postgres.port
}

output "username" {
  value = aws_db_instance.postgres.username
}

output "db_name" {
  value = aws_db_instance.postgres.db_name
}

output "host" {
  value = aws_db_instance.postgres.address
}
