############################
# Current user data
############################

data "aws_caller_identity" "current" {}

locals {
  name             = "${var.project}-${var.environment}"
  hosted_zone_name = var.hosted_zone_name != "" ? var.hosted_zone_name : var.domain_name
  api_domain_name  = var.domain_name != "" ? "${var.api_subdomain}.${var.domain_name}" : ""

  # CORS origins of the web client: the custom domain (when set) and the CloudFront domain.
  api_allowed_origins = concat(
    var.domain_name != "" ? ["https://${var.domain_name}"] : [],
    ["https://${module.frontend.cloudfront_domain_name}"],
  )
}

############################
# ECR
############################

module "ecr" {
  source            = "../ecr"
  repository_name   = local.name
  backend_role_name = module.github_oidc.backend_role_name
}

############################
# GitHub OIDC
############################

module "github_oidc" {
  source       = "../github-oidc"
  project      = var.project
  environment  = var.environment
  github_owner = "prod-forge"

  github_environment   = var.environment
  create_oidc_provider = var.create_github_oidc_provider
}

############################
# Secrets manager
############################

module "secrets_manager" {
  source               = "../secrets_manager"
  secrets_manager_name = var.app_secret_name
  project              = var.project
  environment          = var.environment

  recovery_window_in_days = var.secret_recovery_window_days
}

############################
# VPC
############################

module "vpc" {
  source      = "../vpc"
  project     = var.project
  environment = var.environment

  nat_per_az           = var.vpc_nat_per_az
  enable_vpc_endpoints = var.vpc_enable_endpoints
}

############################
# IAM
############################

module "iam" {
  source        = "../iam"
  project       = var.project
  environment   = var.environment
  db_secret_arn = module.rds.secrets_arn
  kms_arn       = module.secrets_manager.kms_arn

  redis_auth_secret_arn = module.secrets_manager.redis_auth_secret_arn
  jwt_secret_arn        = module.secrets_manager.jwt_secret_arn
  app_secret_arn        = module.secrets_manager.secret_arn
}

############################
# Security Groups
############################

module "security_groups" {
  source      = "../security_groups"
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr
  project     = var.project
  environment = var.environment
}

############################
# Load Balancer
############################

module "load_balancer" {
  source            = "../load_balancer"
  vpc_id            = module.vpc.vpc_id
  sg_alb_id         = module.security_groups.sg_alb_id
  public_subnet_ids = module.vpc.public_subnet_ids
  project           = var.project
  environment       = var.environment

  domain_name        = local.api_domain_name
  certificate_arn    = module.api_certificate.certificate_arn
  access_logs_bucket = module.logs_bucket.bucket_name
  access_logs_prefix = module.logs_bucket.alb_prefix
}

############################
# Access logs (ALB, CloudFront)
############################

module "logs_bucket" {
  source      = "../logs-bucket"
  bucket_name = "${local.name}-access-logs"
}

############################
# WAF
############################

module "waf_alb" {
  count = var.enable_waf ? 1 : 0

  source       = "../waf"
  project      = var.project
  environment  = var.environment
  scope        = "REGIONAL"
  resource_arn = module.load_balancer.lb_arn
}

module "waf_cloudfront" {
  count = var.enable_waf ? 1 : 0

  source      = "../waf"
  project     = var.project
  environment = var.environment
  scope       = "CLOUDFRONT"

  providers = {
    aws = aws.us_east_1
  }
}

############################
# DNS and certificates
############################

module "api_certificate" {
  source         = "../acm-certificate"
  domain_name    = local.api_domain_name
  hosted_zone_id = module.dns.zone_id
}

# CloudFront only accepts certificates from us-east-1.
module "cloudfront_certificate" {
  source         = "../acm-certificate"
  domain_name    = var.domain_name
  hosted_zone_id = module.dns.zone_id

  providers = {
    aws = aws.us_east_1
  }
}

module "dns" {
  source           = "../dns"
  domain_name      = var.domain_name
  hosted_zone_name = local.hosted_zone_name
  api_domain_name  = local.api_domain_name

  alb_dns_name           = module.load_balancer.lb_dns_name
  alb_zone_id            = module.load_balancer.lb_zone_id
  cloudfront_domain_name = module.frontend.cloudfront_domain_name
  cloudfront_zone_id     = module.frontend.cloudfront_hosted_zone_id
}

############################
# ECS Cluster
############################

module "ecs_cluster" {
  source      = "../ecs-cluster"
  project     = var.project
  environment = var.environment
}

############################
# ECS Service
############################

module "ecs_service" {
  source                  = "../ecs-service"
  ecs_cluster_id          = module.ecs_cluster.ecs_cluster_id
  ecs_cluster_name        = module.ecs_cluster.ecs_cluster_name
  ecs_task_definition_arn = module.task_definition.ecs_task_definition_arn
  private_subnet_ids      = module.vpc.private_subnet_ids
  sg_ecs_id               = module.security_groups.sg_ecs_id
  lb_target_group_arn     = module.load_balancer.lb_target_group_arn
  depends_on              = [module.load_balancer.lb_listener]
  project                 = var.project
  environment             = var.environment
  backend_role_name       = module.github_oidc.backend_role_name
  aws_account_id          = data.aws_caller_identity.current.account_id
  task_role_arns          = [module.iam.task_role_arn, module.iam.task_execution_role_arn]

  task_definition_family           = module.task_definition.task_definition_family
  migration_task_definition_family = "${local.name}-migration-task"
  lb_arn_suffix                    = module.load_balancer.lb_arn_suffix
  lb_target_group_arn_suffix       = module.load_balancer.lb_target_group_arn_suffix

  desired_count = var.ecs_desired_count
  min_capacity  = var.ecs_min_capacity
  max_capacity  = var.ecs_max_capacity

  service_discovery_arn = module.service_discovery.backend_service_arn
}

############################
# Service discovery (Cloud Map)
############################

module "service_discovery" {
  source         = "../service-discovery"
  project        = var.project
  vpc_id         = module.vpc.vpc_id
  namespace_name = var.service_namespace
}

############################
# Task Definition
############################

module "task_definition" {
  source                  = "../task_definition"
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arn
  repository_url          = module.ecr.repository_url
  rds_secrets_arn         = module.rds.secrets_arn
  db_name                 = module.rds.db_name
  db_username             = module.rds.username
  db_host                 = module.rds.host
  db_port                 = module.rds.port
  redis_host              = module.redis.redis_host
  redis_port              = module.redis.redis_port
  redis_auth_secret_arn   = module.secrets_manager.redis_auth_secret_arn
  jwt_secret_arn          = module.secrets_manager.jwt_secret_arn
  app_secret_arn          = module.secrets_manager.secret_arn
  project                 = var.project
  environment             = var.environment
  region                  = var.region
  image_tag               = var.image_tag

  cpu                = var.ecs_task_cpu
  memory             = var.ecs_task_memory
  log_retention_days = var.ecs_log_retention_days

  api_allowed_origins = local.api_allowed_origins
  backend_config      = var.backend_config
}

############################
# RDS
############################

module "rds" {
  source                = "../rds"
  db_subnet_group_name  = module.vpc.rds_name
  vpc_security_group_id = module.security_groups.sg_rds_id
  rds_identifier        = "${local.name}-postgres"

  username = var.rds_username
  db_name  = var.rds_db_name

  project     = var.project
  environment = var.environment
  kms_key_arn = module.secrets_manager.kms_arn

  instance_class          = var.rds_instance_class
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection     = var.rds_deletion_protection
  snapshot_identifier     = var.rds_snapshot_identifier
}

############################
# Redis
############################

module "redis" {
  source             = "../redis"
  sg_redis_id        = module.security_groups.sg_redis_id
  private_subnet_ids = module.vpc.private_subnet_ids
  project            = var.project
  environment        = var.environment
  kms_key_arn        = module.secrets_manager.kms_arn
  auth_token         = module.secrets_manager.redis_auth_token

  node_type                = var.redis_node_type
  num_cache_clusters       = var.redis_num_cache_clusters
  snapshot_retention_limit = var.redis_snapshot_retention_limit
}

############################
# VPN
############################

module "server_vpn_certificate" {
  count = var.enable_client_vpn ? 1 : 0

  source            = "../vpn/certificates/server"
  project           = var.project
  environment       = var.environment
  private_key       = var.vpn_server_private_key
  certificate_body  = var.vpn_server_certificate
  certificate_chain = var.vpn_ca_certificate
}

module "client_vpn_certificate" {
  count = var.enable_client_vpn ? 1 : 0

  source           = "../vpn/certificates/client"
  project          = var.project
  environment      = var.environment
  certificate_body = var.vpn_ca_certificate
  private_key      = var.vpn_ca_private_key
}

module "vpn_endpoint" {
  count = var.enable_client_vpn ? 1 : 0

  source                     = "../vpn/vpn-endpoint"
  project                    = var.project
  environment                = var.environment
  server_vpn_certificate_arn = module.server_vpn_certificate[0].arn
  client_vpn_certificate_arn = module.client_vpn_certificate[0].arn
  vpc_main_id                = module.vpc.vpc_id
  sg_vpn_id                  = module.security_groups.sg_vpn_id
}

module "vpn_association" {
  count = var.enable_client_vpn ? 1 : 0

  source          = "../vpn/associations"
  vpn_endpoint_id = module.vpn_endpoint[0].id
  subnet_id       = module.vpc.private_subnet_ids[0]
}

module "vpn_rules" {
  count = var.enable_client_vpn ? 1 : 0

  source          = "../vpn/rules"
  vpn_endpoint_id = module.vpn_endpoint[0].id
  vpc_cidr        = module.vpc.vpc_cidr
}

############################
# Monitoring
############################

module "observability_config" {
  source      = "../observability-config"
  project     = var.project
  environment = var.environment
  source_dir  = "${path.module}/../../observability"
  kms_key_arn = module.secrets_manager.kms_arn

  service_namespace = module.service_discovery.namespace_name
}

module "monitoring_iam" {
  source      = "../monitoring/iam"
  project     = var.project
  environment = var.environment
  kms_key_arn = module.secrets_manager.kms_arn

  grafana_admin_secret_arn        = module.secrets_manager.grafana_admin_secret_arn
  observability_config_bucket_arn = module.observability_config.bucket_arn
}

module "monitoring_sg" {
  source      = "../monitoring/security_group"
  vpc_id      = module.vpc.vpc_id
  project     = var.project
  environment = var.environment

  # Grafana only from the admin CIDRs (empty list: no rule). Prometheus (9090)
  # and SSH (22) are never exposed; the host is reached through SSM.
  monitoring_ingress_rules = length(var.admin_cidr_blocks) == 0 ? [] : [
    {
      description = "Grafana from the admin CIDR blocks"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = var.admin_cidr_blocks
    }
  ]

  monitoring_egress_from_port   = 0
  monitoring_egress_to_port     = 0
  monitoring_egress_protocol    = "-1"
  monitoring_egress_cidr_blocks = ["0.0.0.0/0"]
}

module "monitoring_ec2" {
  source                               = "../monitoring/ec2"
  project                              = var.project
  environment                          = var.environment
  monitoring_ec2_instance_profile_name = module.monitoring_iam.monitoring_ec2_instance_profile_name
  instance_type                        = var.monitoring_instance_type
  sg_monitoring_id                     = module.monitoring_sg.sg_monitoring_id
  public_subnet_id                     = module.vpc.public_subnet_ids[0]
  region                               = var.region

  observability_bucket     = module.observability_config.bucket_name
  grafana_admin_secret_arn = module.secrets_manager.grafana_admin_secret_arn
}

# Prometheus on the monitoring host scrapes the backend tasks on the app port.
resource "aws_vpc_security_group_ingress_rule" "ecs_from_monitoring" {
  security_group_id            = module.security_groups.sg_ecs_id
  description                  = "Prometheus scrape of the application port from the monitoring host"
  ip_protocol                  = "tcp"
  from_port                    = 3000
  to_port                      = 3000
  referenced_security_group_id = module.monitoring_sg.sg_monitoring_id
}

############################
# Alarms and budget
############################

module "alarms" {
  source      = "../alarms"
  project     = var.project
  environment = var.environment

  alert_email        = var.alert_email
  monthly_budget_usd = var.monthly_budget_usd

  ecs_cluster_name           = module.ecs_cluster.ecs_cluster_name
  ecs_service_name           = module.ecs_service.service_name
  lb_arn_suffix              = module.load_balancer.lb_arn_suffix
  lb_target_group_arn_suffix = module.load_balancer.lb_target_group_arn_suffix
  rds_identifier             = module.rds.identifier
  rds_max_connections_alarm  = var.rds_max_connections_alarm
  redis_replication_group_id = module.redis.replication_group_id
  redis_num_cache_clusters   = module.redis.num_cache_clusters
  nat_gateway_ids            = module.vpc.nat_gateway_ids
}

############################
# Frontend (Web Client)
############################

module "frontend" {
  source                 = "../frontend"
  project                = var.project
  environment            = var.environment
  web_client_bucket_name = "${local.name}-web-client"
  assets_bucket_name     = "${local.name}-assets"
  frontend_role_name     = module.github_oidc.frontend_role_name

  domain_name             = var.domain_name
  acm_certificate_arn     = module.cloudfront_certificate.certificate_arn
  web_acl_arn             = var.enable_waf ? module.waf_cloudfront[0].web_acl_arn : null
  logs_bucket_domain_name = module.logs_bucket.bucket_domain_name
  logs_prefix             = module.logs_bucket.cloudfront_prefix
}

############################
# Account security baseline
############################

module "security_baseline" {
  source      = "../security-baseline"
  project     = var.project
  environment = var.environment

  enable_cloudtrail      = var.enable_account_security_services
  enable_guardduty       = var.enable_account_security_services
  enable_access_analyzer = var.enable_account_security_services
}
