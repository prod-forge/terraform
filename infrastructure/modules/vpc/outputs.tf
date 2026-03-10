output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "rds_subnet_id" {
  value = aws_db_subnet_group.main.id
}

output "rds_name" {
  value = aws_db_subnet_group.main.name
}

output "vpc_cidr" {
  value = var.cidr
}
