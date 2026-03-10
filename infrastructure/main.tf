############################
# Current user data
############################

data "aws_caller_identity" "current" {}

############################
# Github OIDC
############################

module "github_oidc" {
  source         = "./modules/github-oidc"
  github_owner   = "prod-forge"
  github_repo    = "backend"
  aws_account_id = data.aws_caller_identity.current.account_id
}

############################
# Secrets manager
############################

module "secrets_manager" {
  secrets_manager_name = "prod_forge/backend/config-v1"
  source               = "./modules/secrets_manager"
}

############################
# ECR
############################

module "ecr" {
  source          = "./modules/ecr"
  repository_name = var.project
}

############################
# VPC
############################

module "vpc" {
  source = "./modules/vpc"
}

############################
# IAM
############################

module "iam" {
  source          = "./modules/iam"
  rds_secrets_arn = module.rds.secrets_arn
  kms_arn         = module.secrets_manager.kms_arn
}

############################
# Security Groups
############################

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
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
  source                  = "./modules/ecs-service"
  ecs_cluster_id          = module.ecs_cluster.ecs_cluster_id
  ecs_task_definition_arn = module.task_definition.ecs_task_definition_arn
  public_subnet_ids       = module.vpc.public_subnet_ids
  sg_ecs_id               = module.security_groups.sg_ecs_id
  lb_target_group_arn     = module.load_balancer.lb_target_group_arn
  depends_on              = [module.load_balancer.lb_listener]
  project                 = var.project
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
  project                 = var.project
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
}

############################
# Redis
############################

module "redis" {
  source             = "./modules/redis"
  sg_redis_id        = module.security_groups.sg_redis_id
  private_subnet_ids = module.vpc.private_subnet_ids
  project            = var.project
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

module "monitoring_ssh" {
  source          = "./modules/monitoring/ssh-module"
  key_name        = "my-key"
  public_key_path = "ssh/my-key.pub"
}

module "monitoring_sg" {
  source = "./modules/monitoring/security_group"
  vpc_id = module.vpc.vpc_id

  monitoring_ingress_rules = [
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
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
  key_pair_key_name                    = module.monitoring_ssh.key_name
  sg_monitoring_id                     = module.monitoring_sg.sg_monitoring_id
  public_subnet_id                     = module.vpc.public_subnet_ids[0]
  repository_url                       = module.ecr.repository_url
}
