############################
# Current user data
############################

data "aws_caller_identity" "current" {}

locals {
  hosted_zone_name = var.hosted_zone_name != "" ? var.hosted_zone_name : var.domain_name
  api_domain_name  = var.domain_name != "" ? "${var.api_subdomain}.${var.domain_name}" : ""
}

############################
# ECR
############################

module "ecr" {
  source                   = "./modules/ecr"
  repository_name          = var.project
  github_actions_role_name = module.github_oidc.github_actions_role_name
}

############################
# GitHub OIDC
############################

module "github_oidc" {
  source       = "./modules/github-oidc"
  github_owner = "prod-forge"
  github_repos = ["backend", "frontend"]
}

############################
# Secrets manager
############################

module "secrets_manager" {
  secrets_manager_name = "prod_forge/backend/config-v1"
  source               = "./modules/secrets_manager"
  project              = var.project
  environment          = var.environment
}

############################
# VPC
############################

module "vpc" {
  source  = "./modules/vpc"
  project = var.project

  nat_per_az           = var.vpc_nat_per_az
  enable_vpc_endpoints = var.vpc_enable_endpoints
}

############################
# IAM
############################

module "iam" {
  source          = "./modules/iam"
  rds_secrets_arn = module.rds.secrets_arn
  kms_arn         = module.secrets_manager.kms_arn

  redis_auth_secret_arn = module.secrets_manager.redis_auth_secret_arn
  jwt_secret_arn        = module.secrets_manager.jwt_secret_arn
}

############################
# Security Groups
############################

module "security_groups" {
  source   = "./modules/security_groups"
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr
  project  = var.project
}

############################
# Load Balancer
############################

module "load_balancer" {
  source            = "./modules/load_balancer"
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
  source      = "./modules/logs-bucket"
  project     = var.project
  environment = var.environment
  bucket_name = "${var.project}-access-logs"
}

############################
# WAF
############################

module "waf_alb" {
  source       = "./modules/waf"
  project      = var.project
  environment  = var.environment
  scope        = "REGIONAL"
  resource_arn = module.load_balancer.lb_arn
}

module "waf_cloudfront" {
  source      = "./modules/waf"
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
  source         = "./modules/acm-certificate"
  domain_name    = local.api_domain_name
  hosted_zone_id = module.dns.zone_id
}

# CloudFront only accepts certificates from us-east-1.
module "cloudfront_certificate" {
  source         = "./modules/acm-certificate"
  domain_name    = var.domain_name
  hosted_zone_id = module.dns.zone_id

  providers = {
    aws = aws.us_east_1
  }
}

module "dns" {
  source           = "./modules/dns"
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
  source  = "./modules/ecs-cluster"
  project = var.project
}

############################
# ECS Service
############################

module "ecs_service" {
  source                   = "./modules/ecs-service"
  ecs_cluster_id           = module.ecs_cluster.ecs_cluster_id
  ecs_cluster_name         = module.ecs_cluster.ecs_cluster_name
  ecs_task_definition_arn  = module.task_definition.ecs_task_definition_arn
  private_subnet_ids       = module.vpc.private_subnet_ids
  sg_ecs_id                = module.security_groups.sg_ecs_id
  lb_target_group_arn      = module.load_balancer.lb_target_group_arn
  depends_on               = [module.load_balancer.lb_listener]
  project                  = var.project
  github_actions_role_name = module.github_oidc.github_actions_role_name
  aws_account_id           = data.aws_caller_identity.current.account_id

  task_definition_family           = module.task_definition.task_definition_family
  migration_task_definition_family = "${var.project}-migration-task"
  lb_arn_suffix                    = module.load_balancer.lb_arn_suffix
  lb_target_group_arn_suffix       = module.load_balancer.lb_target_group_arn_suffix

  desired_count = var.ecs_desired_count
  min_capacity  = var.ecs_min_capacity
  max_capacity  = var.ecs_max_capacity
}

############################
# Task Definition
############################

module "task_definition" {
  source                  = "./modules/task_definition"
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
  project                 = var.project
  region                  = var.region

  cpu                = var.ecs_task_cpu
  memory             = var.ecs_task_memory
  log_retention_days = var.ecs_log_retention_days
}

############################
# RDS
############################

module "rds" {
  source                = "./modules/rds"
  db_subnet_group_name  = module.vpc.rds_name
  vpc_security_group_id = module.security_groups.sg_rds_id
  rds_identifier        = var.rds_identifier

  username = var.rds_username
  db_name  = var.rds_db_name

  project     = var.project
  environment = var.environment
  kms_key_arn = module.secrets_manager.kms_arn

  instance_class          = var.rds_instance_class
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection     = var.rds_deletion_protection
}

############################
# Redis
############################

module "redis" {
  source             = "./modules/redis"
  sg_redis_id        = module.security_groups.sg_redis_id
  private_subnet_ids = module.vpc.private_subnet_ids
  project            = var.project
  kms_key_arn        = module.secrets_manager.kms_arn
  auth_token         = module.secrets_manager.redis_auth_token

  node_type                = var.redis_node_type
  snapshot_retention_limit = var.redis_snapshot_retention_limit
}

############################
# VPN
############################

module "server_vpn_certificate" {
  source            = "./modules/vpn/certificates/server"
  private_key       = file("vpn-key/server.key")
  certificate_body  = file("vpn-key/server.crt")
  certificate_chain = file("vpn-key/ca.crt")
}

module "client_vpn_certificate" {
  source           = "./modules/vpn/certificates/client"
  certificate_body = file("vpn-key/ca.crt")
  private_key      = file("vpn-key/ca.key")
}

module "vpn_endpoint" {
  source                     = "./modules/vpn/vpn-endpoint"
  server_vpn_certificate_arn = module.server_vpn_certificate.arn
  client_vpn_certificate_arn = module.client_vpn_certificate.arn
  vpc_main_id                = module.vpc.vpc_id
  sg_vpn_id                  = module.security_groups.sg_vpn_id
}

module "vpn_association" {
  source          = "./modules/vpn/associations"
  vpn_endpoint_id = module.vpn_endpoint.id
  subnet_id       = module.vpc.private_subnet_ids[0]
}

module "vpn_rules" {
  source          = "./modules/vpn/rules"
  vpn_endpoint_id = module.vpn_endpoint.id
  vpc_cidr        = module.vpc.vpc_cidr
}

############################
# Monitoring
############################

module "monitoring_iam" {
  source      = "./modules/monitoring/iam"
  secret_arn  = module.secrets_manager.secret_arn
  kms_key_arn = module.secrets_manager.kms_arn
}

module "monitoring_sg" {
  source = "./modules/monitoring/security_group"
  vpc_id = module.vpc.vpc_id

  # Grafana only from the admin CIDRs (empty list: no rule). Prometheus (9090)
  # and SSH (22) are never exposed; the host is reached through SSM.
  monitoring_ingress_rules = length(var.admin_cidr_blocks) == 0 ? [] : [
    {
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
  source                               = "./modules/monitoring/ec2"
  monitoring_ec2_instance_profile_name = module.monitoring_iam.monitoring_ec2_instance_profile_name
  instance_type                        = var.monitoring_instance_type
  sg_monitoring_id                     = module.monitoring_sg.sg_monitoring_id
  public_subnet_id                     = module.vpc.public_subnet_ids[0]
  repository_url                       = module.ecr.repository_url
  secret_id                            = module.secrets_manager.secret_arn
  region                               = var.region
}

############################
# Alarms and budget
############################

module "alarms" {
  source      = "./modules/alarms"
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
  source                   = "./modules/frontend"
  project                  = var.project
  environment              = var.environment
  web_client_bucket_name   = "${var.project}-web-client"
  assets_bucket_name       = "${var.project}-assets"
  github_actions_role_name = module.github_oidc.github_actions_role_name

  domain_name             = var.domain_name
  acm_certificate_arn     = module.cloudfront_certificate.certificate_arn
  web_acl_arn             = module.waf_cloudfront.web_acl_arn
  logs_bucket_domain_name = module.logs_bucket.bucket_domain_name
  logs_prefix             = module.logs_bucket.cloudfront_prefix
}
