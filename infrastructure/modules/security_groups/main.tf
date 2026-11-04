# name_prefix gives every replacement a unique name, so create_before_destroy can create the new
# group while the old one exists; dependents (ALB, ECS, RDS, Redis, Client VPN) switch before it is deleted.

resource "aws_security_group" "alb_sg" {
  #checkov:skip=CKV_AWS_260: the ALB is the public entry point; port 80 only redirects to HTTPS when a domain is configured
  name_prefix = "${var.project}-alb-sg-"
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

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs_sg" {
  name_prefix = "${var.project}-ecs-sg-"
  description = "ECS tasks: ingress from the ALB, egress to HTTPS, RDS and Redis"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Application port from the ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Egress rules are separate resources because RDS and Redis groups reference ecs_sg in their ingress.

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
  name_prefix = "${var.project}-rds-sg-"
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

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "vpn_sg" {
  name_prefix = "${var.project}-client-vpn-sg-"
  description = "Client VPN endpoint network interfaces"
  vpc_id      = var.vpc_id

  ingress {
    description = "All traffic from inside the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "redis_sg" {
  name_prefix = "${var.project}-redis-sg-"
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

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
