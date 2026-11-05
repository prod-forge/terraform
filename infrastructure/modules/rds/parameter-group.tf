resource "aws_db_parameter_group" "postgres" {
  name_prefix = "${var.rds_identifier}-"
  family      = "postgres18"

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "pg_stat_statements.track"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "500"
  }

  # Already the PostgreSQL 15+ default on RDS; set explicitly so a client without TLS is
  # refused by configuration, not by a default. The backend connects with DATABASE_SSL=true.
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }
}
