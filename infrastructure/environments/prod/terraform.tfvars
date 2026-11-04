project     = "prod-forge-todolist"
environment = "prod"
region      = "eu-central-1"
owner       = "devops"
cost_center = "prod-forge"
repository  = "github.com/prod-forge/terraform"

app_secret_name             = "prod_forge/backend/config-v1"
secret_recovery_window_days = 30
# prod owns the account-wide GitHub OIDC provider; dev in the same account reads it.
create_github_oidc_provider = true
# prod owns the account-level CloudTrail trail, GuardDuty detector and Access Analyzer.
enable_account_security_services = true

# Must equal the live master username: changing it replaces the database.
rds_username = "new_username"
rds_db_name  = "todolist"

rds_instance_class          = "db.t4g.medium"
rds_multi_az                = true
rds_backup_retention_period = 7
rds_deletion_protection     = true
# About 80% of max_connections for db.t4g.medium.
rds_max_connections_alarm = 320

redis_node_type                = "cache.t4g.small"
redis_num_cache_clusters       = 2
redis_snapshot_retention_limit = 7

vpc_nat_per_az       = true
vpc_enable_endpoints = true

ecs_desired_count      = 2
ecs_min_capacity       = 2
ecs_max_capacity       = 10
ecs_task_cpu           = 512
ecs_task_memory        = 1024
ecs_log_retention_days = 30

# Backend tunables (task environment). Omitted attributes use the backend defaults.
# Sentry: put {"SENTRY_DSN":"<dsn>"} into the app_secret_name secret first, then set sentry_enabled = true.
backend_config = {
  log_level           = "info"
  database_log_levels = ["warn", "error"]
  # ecs_max_capacity (10) x 10 stays well below max_connections of db.t4g.medium.
  database_pool_max            = 10
  jwt_ttl                      = 3600
  throttle_enabled             = true
  throttle_limit               = 60
  throttle_ttl                 = 60000
  shutdown_drain_ms            = 10000
  shutdown_inflight_timeout_ms = 20000
  sentry_enabled               = false
}

# Set to the owned domain to enable HTTPS on the ALB, the CloudFront custom domain and DNS records.
domain_name       = ""
hosted_zone_name  = ""
api_subdomain     = "api"
enable_waf        = true
service_namespace = "prod-forge-todolist.local"

# Reads server.crt, server.key, ca.crt and ca.key from infrastructure/vpn-key (see docs/debugging.md).
enable_client_vpn = true

# Replace with the real on-call mailbox: alarms and budget notifications go here (the subscription must be confirmed).
alert_email = "alerts@example.com"
# The budget has no cost filter, so it tracks the whole account: prod owns it and
# sizes it above the combined dev and prod estimate (docs/cost.md).
monthly_budget_usd = 800

monitoring_instance_type = "t3.small"
# Grafana is reachable only from these CIDRs. Empty keeps it closed; use SSM port forwarding.
admin_cidr_blocks = []
