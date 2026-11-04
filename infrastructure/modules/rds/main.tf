resource "aws_db_instance" "postgres" {
  #checkov:skip=CKV_AWS_157: Multi-AZ comes from var.multi_az; prod sets true, dev runs a single instance to halve the cost
  #checkov:skip=CKV_AWS_293: deletion protection comes from var.deletion_protection; prod sets true, dev stays off so it can be destroyed
  identifier          = var.rds_identifier
  engine              = "postgres"
  engine_version      = "18"
  instance_class      = var.instance_class
  allocated_storage   = var.allocated_storage
  publicly_accessible = false

  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn
  multi_az              = var.multi_az

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  username = var.username
  db_name  = var.db_name

  iam_database_authentication_enabled = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.vpc_security_group_id]
  parameter_group_name   = aws_db_parameter_group.postgres.name

  backup_retention_period    = var.backup_retention_period
  backup_window              = var.backup_window
  maintenance_window         = var.maintenance_window
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project}-${var.environment}-final"

  performance_insights_enabled    = true
  performance_insights_kms_key_id = var.kms_key_arn
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.monitoring.arn
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Restores the first instance from a snapshot (see docs/migration-to-environments.md).
  # Changing it later would replace the instance, so it only applies on creation.
  snapshot_identifier = var.snapshot_identifier

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}

data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name               = "${var.rds_identifier}-enhanced-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
