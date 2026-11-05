locals {
  https_enabled = var.domain_name != ""
}

resource "aws_lb" "app" {
  #checkov:skip=CKV_AWS_150: deletion protection is enabled when var.environment is prod; dev stays off so it can be destroyed freely
  name               = "${var.project}-${var.environment}-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.sg_alb_id]

  enable_deletion_protection = var.environment == "prod"
  drop_invalid_header_fields = true

  access_logs {
    enabled = true
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project}-${var.environment}-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # The backend drains on SIGTERM within about 30 s (see guide/scaling.md).
  deregistration_delay = 30

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

############################
# HTTP listener
############################

# With a domain, port 80 only redirects to HTTPS. Without one there is no
# certificate, so port 80 forwards to the app (documented insecure fallback).
resource "aws_lb_listener" "app" {
  #checkov:skip=CKV_AWS_2: port 80 redirects to HTTPS whenever var.domain_name is set; plain forward is the documented fallback for environments without a domain
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = local.https_enabled ? "redirect" : "forward"
    target_group_arn = local.https_enabled ? null : aws_lb_target_group.app.arn

    dynamic "redirect" {
      for_each = local.https_enabled ? [1] : []

      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

############################
# HTTPS listener
############################

resource "aws_lb_listener" "https" {
  count = local.https_enabled ? 1 : 0

  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

############################
# Block /metrics
############################

# The backend serves /metrics and /metrics/database without authentication.
# Prometheus scrapes the task IPs directly, so the ALB never needs to expose them.
resource "aws_lb_listener_rule" "block_metrics" {
  listener_arn = local.https_enabled ? aws_lb_listener.https[0].arn : aws_lb_listener.app.arn
  priority     = 1

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  condition {
    path_pattern {
      values = ["/metrics*", "/api/metrics*"]
    }
  }
}
