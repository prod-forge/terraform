# name_prefix gives every replacement a unique name, so create_before_destroy can create the new
# group while the old one exists; dependents (ALB, ECS, RDS, Redis, Client VPN) switch before it is deleted.

resource "aws_security_group" "alb_sg" {
  #checkov:skip=CKV2_AWS_5: attached to the ALB in module.load_balancer; Checkov does not follow the id across modules
  #checkov:skip=CKV_AWS_260: the ALB is the public entry point; port 80 only redirects to HTTPS when a domain is configured
  name_prefix = "${var.project}-${var.environment}-alb-sg-"
  description = "Public HTTP access to the application load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Targets and health checks are the ECS tasks on the application port.
  egress {
    description = "Application port to the ECS tasks inside the VPC"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs_sg" {
  #checkov:skip=CKV2_AWS_5: attached to the ECS service in module.ecs_service; Checkov does not follow the id across modules
  name_prefix = "${var.project}-${var.environment}-ecs-sg-"
  description = "ECS tasks: ingress from the ALB and the monitoring host, egress to HTTPS, RDS and Redis"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

# Rules of ecs_sg are separate resources: the monitoring ingress rule is added from the root, and inline
# rules cannot be mixed with standalone ones. Egress is split because RDS and Redis reference ecs_sg too.

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs_sg.id
  description                  = "Application port from the ALB"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs_sg.id
  description       = "HTTPS to AWS APIs (VPC endpoints or NAT) and external services such as Sentry"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ecs_postgres" {
  security_group_id            = aws_security_group.ecs_sg.id
  description                  = "PostgreSQL to RDS"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.rds_sg.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_redis" {
  security_group_id            = aws_security_group.ecs_sg.id
  description                  = "Redis (TLS) to ElastiCache"
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = aws_security_group.redis_sg.id
}

resource "aws_security_group" "rds_sg" {
  #checkov:skip=CKV2_AWS_5: attached to the RDS instance in module.rds; Checkov does not follow the id across modules
  name_prefix = "${var.project}-${var.environment}-rds-sg-"
  description = "PostgreSQL access from ECS tasks and the Client VPN"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from ECS tasks and the Client VPN"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [
      aws_security_group.ecs_sg.id,
      aws_security_group.vpn_sg.id
    ]
  }

  # No egress rules: security groups are stateful, so replies to the
  # allowed ingress need none, and the data stores open no connections.

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "vpn_sg" {
  #checkov:skip=CKV2_AWS_5: attached to the Client VPN endpoint when var.enable_client_vpn is true (prod); dev keeps the group without an endpoint
  name_prefix = "${var.project}-${var.environment}-client-vpn-sg-"
  description = "Client VPN endpoint network interfaces"
  vpc_id      = var.vpc_id

  ingress {
    description = "All traffic from inside the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # The VPN authorizes only the VPC CIDR, so clients never need outbound traffic beyond it.
  egress {
    description = "All traffic to the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "redis_sg" {
  #checkov:skip=CKV2_AWS_5: attached to the Redis replication group in module.redis; Checkov does not follow the id across modules
  name_prefix = "${var.project}-${var.environment}-redis-sg-"
  description = "Redis access from ECS tasks and the Client VPN"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis (TLS) from ECS tasks and the Client VPN"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [
      aws_security_group.ecs_sg.id,
      aws_security_group.vpn_sg.id
    ]
  }

  # No egress rules: security groups are stateful, so replies to the
  # allowed ingress need none, and the data stores open no connections.

  lifecycle {
    create_before_destroy = true
  }
}
