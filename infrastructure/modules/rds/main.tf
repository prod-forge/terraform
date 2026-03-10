resource "aws_db_instance" "postgres" {
  identifier          = var.rds_identifier
  engine              = "postgres"
  engine_version      = "18"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  publicly_accessible = false

  manage_master_user_password = true

  username = var.username
  db_name  = var.db_name

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.vpc_security_group_id]

  skip_final_snapshot = true
}
