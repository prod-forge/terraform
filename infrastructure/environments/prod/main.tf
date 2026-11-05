############################
# Client VPN key material
############################

# The key files are git-ignored. Missing files resolve to "" so validate and
# offline tests work in a fresh clone; the enable_client_vpn validation in
# variables.tf rejects a plan that enables the VPN without them.
locals {
  vpn_key_dir = "${path.root}/${var.vpn_key_dir}"
  vpn_pem = {
    for name, file_name in {
      server_certificate = "server.crt"
      server_private_key = "server.key"
      ca_certificate     = "ca.crt"
      ca_private_key     = "ca.key"
    } : name => fileexists("${local.vpn_key_dir}/${file_name}") ? file("${local.vpn_key_dir}/${file_name}") : ""
  }
}

############################
# Stack
############################

module "stack" {
  source = "../../modules/stack"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project     = var.project
  environment = var.environment
  region      = var.region

  app_secret_name             = var.app_secret_name
  secret_recovery_window_days = var.secret_recovery_window_days
  create_github_oidc_provider = var.create_github_oidc_provider

  enable_account_security_services = var.enable_account_security_services

  vpc_nat_per_az       = var.vpc_nat_per_az
  vpc_enable_endpoints = var.vpc_enable_endpoints

  rds_username                = var.rds_username
  rds_db_name                 = var.rds_db_name
  rds_instance_class          = var.rds_instance_class
  rds_multi_az                = var.rds_multi_az
  rds_backup_retention_period = var.rds_backup_retention_period
  rds_deletion_protection     = var.rds_deletion_protection
  rds_snapshot_identifier     = var.rds_snapshot_identifier
  rds_max_connections_alarm   = var.rds_max_connections_alarm

  redis_node_type                = var.redis_node_type
  redis_num_cache_clusters       = var.redis_num_cache_clusters
  redis_snapshot_retention_limit = var.redis_snapshot_retention_limit

  ecs_desired_count      = var.ecs_desired_count
  ecs_min_capacity       = var.ecs_min_capacity
  ecs_max_capacity       = var.ecs_max_capacity
  ecs_task_cpu           = var.ecs_task_cpu
  ecs_task_memory        = var.ecs_task_memory
  ecs_log_retention_days = var.ecs_log_retention_days
  backend_config         = var.backend_config

  domain_name      = var.domain_name
  hosted_zone_name = var.hosted_zone_name
  api_subdomain    = var.api_subdomain
  enable_waf       = var.enable_waf

  service_namespace = var.service_namespace

  enable_client_vpn      = var.enable_client_vpn
  vpn_server_certificate = local.vpn_pem.server_certificate
  vpn_server_private_key = local.vpn_pem.server_private_key
  vpn_ca_certificate     = local.vpn_pem.ca_certificate
  vpn_ca_private_key     = local.vpn_pem.ca_private_key

  image_tag = var.image_tag

  monitoring_instance_type = var.monitoring_instance_type
  admin_cidr_blocks        = var.admin_cidr_blocks

  alert_email        = var.alert_email
  monthly_budget_usd = var.monthly_budget_usd
}
