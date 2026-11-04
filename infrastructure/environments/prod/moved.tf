# The former infrastructure/ root became module.stack. These blocks move every
# address of the live prod state under it, so no resource is recreated by the
# move itself. Name changes are not addresses: those replacements are listed in
# docs/migration-to-environments.md. Moves whose source is not in the state are
# no-ops. Keep this file until every environment has been applied once.

moved {
  from = module.ecr
  to   = module.stack.module.ecr
}

moved {
  from = module.github_oidc
  to   = module.stack.module.github_oidc
}

moved {
  from = module.secrets_manager
  to   = module.stack.module.secrets_manager
}

moved {
  from = module.vpc
  to   = module.stack.module.vpc
}

moved {
  from = module.iam
  to   = module.stack.module.iam
}

moved {
  from = module.security_groups
  to   = module.stack.module.security_groups
}

moved {
  from = module.load_balancer
  to   = module.stack.module.load_balancer
}

moved {
  from = module.logs_bucket
  to   = module.stack.module.logs_bucket
}

moved {
  from = module.api_certificate
  to   = module.stack.module.api_certificate
}

moved {
  from = module.cloudfront_certificate
  to   = module.stack.module.cloudfront_certificate
}

moved {
  from = module.dns
  to   = module.stack.module.dns
}

moved {
  from = module.ecs_cluster
  to   = module.stack.module.ecs_cluster
}

moved {
  from = module.ecs_service
  to   = module.stack.module.ecs_service
}

moved {
  from = module.service_discovery
  to   = module.stack.module.service_discovery
}

moved {
  from = module.task_definition
  to   = module.stack.module.task_definition
}

moved {
  from = module.rds
  to   = module.stack.module.rds
}

moved {
  from = module.redis
  to   = module.stack.module.redis
}

moved {
  from = module.observability_config
  to   = module.stack.module.observability_config
}

moved {
  from = module.monitoring_iam
  to   = module.stack.module.monitoring_iam
}

moved {
  from = module.monitoring_sg
  to   = module.stack.module.monitoring_sg
}

moved {
  from = module.monitoring_ec2
  to   = module.stack.module.monitoring_ec2
}

moved {
  from = module.alarms
  to   = module.stack.module.alarms
}

moved {
  from = module.frontend
  to   = module.stack.module.frontend
}

# Optional in the stack (enable_waf, enable_client_vpn), so they gained an index.

moved {
  from = module.waf_alb
  to   = module.stack.module.waf_alb[0]
}

moved {
  from = module.waf_cloudfront
  to   = module.stack.module.waf_cloudfront[0]
}

moved {
  from = module.server_vpn_certificate
  to   = module.stack.module.server_vpn_certificate[0]
}

moved {
  from = module.client_vpn_certificate
  to   = module.stack.module.client_vpn_certificate[0]
}

moved {
  from = module.vpn_endpoint
  to   = module.stack.module.vpn_endpoint[0]
}

moved {
  from = module.vpn_association
  to   = module.stack.module.vpn_association[0]
}

moved {
  from = module.vpn_rules
  to   = module.stack.module.vpn_rules[0]
}

moved {
  from = aws_vpc_security_group_ingress_rule.ecs_from_monitoring
  to   = module.stack.aws_vpc_security_group_ingress_rule.ecs_from_monitoring
}
