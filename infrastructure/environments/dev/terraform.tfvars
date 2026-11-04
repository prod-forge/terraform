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

# Backend tunables (task environment). Omitted attributes use the backend defaults.
# Sentry: put {"SENTRY_DSN":"<dsn>"} into the app_secret_name secret first, then set sentry_enabled = true.
backend_config = {
  log_level           = "trace"
  database_log_levels = ["warn", "error"]
  # ecs_max_capacity (2) x 5 stays well below max_connections of db.t4g.micro.
  database_pool_max            = 5
  jwt_ttl                      = 3600
  throttle_enabled             = true
  throttle_limit               = 60
  throttle_ttl                 = 60000
  shutdown_drain_ms            = 10000
  shutdown_inflight_timeout_ms = 20000
  sentry_enabled               = false
}

domain_name       = ""
hosted_zone_name  = ""
api_subdomain     = "api"
enable_waf        = false
service_namespace = "prod-forge-todolist-dev.local"

# Dev is reached through SSM; set true and provide the key files to add a Client VPN.
enable_client_vpn = false

# Empty: no alarm subscription is created (no pending confirmation email).
alert_email = ""
# 0: no budget. The account-wide budget is owned by prod (docs/cost.md).
monthly_budget_usd = 0

monitoring_instance_type = "t3.small"
admin_cidr_blocks        = []
