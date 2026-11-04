project     = "prod-forge-todolist"
environment = "dev"
region      = "eu-central-1"
owner       = "devops"
cost_center = "prod-forge"
repository  = "github.com/prod-forge/terraform"

app_secret_name = "prod_forge/backend/dev/config-v1"
# Immediate deletion lets a destroyed dev be recreated with the same secret names.
secret_recovery_window_days = 0
# The OIDC provider is account-wide and owned by prod. Set true when dev has its own AWS account.
create_github_oidc_provider = false
# Covered by prod in a shared account. Set true when dev has its own AWS account.
enable_account_security_services = false

rds_username = "new_username"
rds_db_name  = "todolist"

rds_instance_class          = "db.t4g.micro"
rds_multi_az                = false
rds_backup_retention_period = 1
rds_deletion_protection     = false
# About 80% of max_connections (about 110) for db.t4g.micro.
rds_max_connections_alarm = 90

redis_node_type                = "cache.t4g.micro"
redis_num_cache_clusters       = 1
redis_snapshot_retention_limit = 1

vpc_nat_per_az       = false
vpc_enable_endpoints = false

ecs_desired_count      = 1
ecs_min_capacity       = 1
ecs_max_capacity       = 2
ecs_task_cpu           = 256
ecs_task_memory        = 512
ecs_log_retention_days = 7

domain_name      = ""
hosted_zone_name = ""
api_subdomain    = "api"
enable_waf       = false

# Dev is reached through SSM; set true and provide the key files to add a Client VPN.
enable_client_vpn = false

alert_email        = "alerts@example.com"
monthly_budget_usd = 200

monitoring_instance_type = "t3.small"
admin_cidr_blocks        = []
