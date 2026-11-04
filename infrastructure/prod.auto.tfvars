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

redis_node_type                = "cache.t4g.small"
redis_snapshot_retention_limit = 7

vpc_nat_per_az       = true
vpc_enable_endpoints = true

ecs_desired_count      = 2
ecs_min_capacity       = 2
ecs_max_capacity       = 10
ecs_task_cpu           = 512
ecs_task_memory        = 1024
ecs_log_retention_days = 30

# Set to the owned domain to enable HTTPS on the ALB, the CloudFront custom domain and DNS records.
domain_name      = ""
hosted_zone_name = ""
api_subdomain    = "api"

# Replace with the real on-call mailbox: alarms and budget notifications go here (the subscription must be confirmed).
alert_email        = "alerts@example.com"
monthly_budget_usd = 400

monitoring_instance_type = "t3.small"
# Grafana is reachable only from these CIDRs. Empty keeps it closed; use SSM port forwarding.
admin_cidr_blocks = []
# About 80% of max_connections for db.t4g.medium.
rds_max_connections_alarm = 320
