project        = "prod-forge-todolist"
environment    = "prod"
region         = "eu-central-1"
rds_identifier = "prod-forge-database"
rds_username   = "new_username"
rds_db_name    = "todolist"

rds_instance_class          = "db.t4g.medium"
rds_multi_az                = true
rds_backup_retention_period = 7
rds_deletion_protection     = true
