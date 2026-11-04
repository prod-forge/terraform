data "aws_caller_identity" "current" {}

locals {
  prefix          = "${var.project}-${var.environment}"
  email_enabled   = var.alert_email != ""
  budget_enabled  = local.email_enabled && var.monthly_budget_usd > 0
  redis_node_ids  = [for i in range(var.redis_num_cache_clusters) : format("%s-%03d", var.redis_replication_group_id, i + 1)]
  alarm_actions   = [aws_sns_topic.alerts.arn]
  five_minutes    = 300
  rds_min_free_gb = 2
}

############################
# SNS topic
############################

resource "aws_kms_key" "alerts" {
  description         = "${local.prefix} alerts topic"
  enable_key_rotation = true

  # CloudWatch cannot publish to a topic encrypted with the AWS managed key.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AlarmPublishers"
        Effect    = "Allow"
        Principal = { Service = ["cloudwatch.amazonaws.com"] }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey*"]
        Resource  = "*"
      }
    ]
  })
}

resource "aws_sns_topic" "alerts" {
  name              = "${local.prefix}-alerts"
  kms_master_key_id = aws_kms_key.alerts.arn
}

resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AlarmPublishers"
        Effect    = "Allow"
        Principal = { Service = ["cloudwatch.amazonaws.com"] }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.alerts.arn
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "email" {
  count = local.email_enabled ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

############################
# ECS
############################

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${local.prefix}-ecs-cpu-high"
  alarm_description   = "ECS service CPU above 80% for 5 minutes"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  dimensions          = { ClusterName = var.ecs_cluster_name, ServiceName = var.ecs_service_name }
  statistic           = "Average"
  period              = local.five_minutes
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name          = "${local.prefix}-ecs-memory-high"
  alarm_description   = "ECS service memory above 80% for 5 minutes"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  dimensions          = { ClusterName = var.ecs_cluster_name, ServiceName = var.ecs_service_name }
  statistic           = "Average"
  period              = local.five_minutes
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}

############################
# ALB
############################

resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  alarm_name          = "${local.prefix}-alb-5xx-rate-high"
  alarm_description   = "More than 5% of ALB requests answered with 5xx by the targets for 5 minutes"
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions

  metric_query {
    id          = "rate"
    expression  = "100 * errors / requests"
    label       = "5xx rate (%)"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      dimensions  = { LoadBalancer = var.lb_arn_suffix }
      period      = local.five_minutes
      stat        = "Sum"
    }
  }

  metric_query {
    id = "requests"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      dimensions  = { LoadBalancer = var.lb_arn_suffix }
      period      = local.five_minutes
      stat        = "Sum"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${local.prefix}-alb-unhealthy-hosts"
  alarm_description   = "At least one target is unhealthy"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  dimensions          = { LoadBalancer = var.lb_arn_suffix, TargetGroup = var.lb_target_group_arn_suffix }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "alb_latency_p95" {
  alarm_name          = "${local.prefix}-alb-latency-p95-high"
  alarm_description   = "p95 target response time above 0.5 seconds for 5 minutes"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = { LoadBalancer = var.lb_arn_suffix }
  extended_statistic  = "p95"
  period              = local.five_minutes
  evaluation_periods  = 1
  threshold           = 0.5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}

############################
# RDS
############################

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.prefix}-rds-cpu-high"
  alarm_description   = "RDS CPU above 80% for 5 minutes"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  statistic           = "Average"
  period              = local.five_minutes
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${local.prefix}-rds-free-storage-low"
  alarm_description   = "RDS free storage below ${local.rds_min_free_gb} GB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  statistic           = "Minimum"
  period              = local.five_minutes
  evaluation_periods  = 1
  threshold           = local.rds_min_free_gb * 1024 * 1024 * 1024
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.prefix}-rds-connections-high"
  alarm_description   = "RDS connections above ${var.rds_max_connections_alarm} (about 80% of max_connections)"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  dimensions          = { DBInstanceIdentifier = var.rds_identifier }
  statistic           = "Maximum"
  period              = local.five_minutes
  evaluation_periods  = 1
  threshold           = var.rds_max_connections_alarm
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}

############################
# Redis (one alarm per node)
############################

resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  count = length(local.redis_node_ids)

  alarm_name          = "${local.prefix}-redis-cpu-high-${local.redis_node_ids[count.index]}"
  alarm_description   = "Redis engine CPU above 80% for 5 minutes on ${local.redis_node_ids[count.index]}"
  namespace           = "AWS/ElastiCache"
  metric_name         = "EngineCPUUtilization"
  dimensions          = { CacheClusterId = local.redis_node_ids[count.index] }
  statistic           = "Average"
  period              = local.five_minutes
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "redis_evictions" {
  count = length(local.redis_node_ids)

  alarm_name          = "${local.prefix}-redis-evictions-${local.redis_node_ids[count.index]}"
  alarm_description   = "Redis evicted keys on ${local.redis_node_ids[count.index]}"
  namespace           = "AWS/ElastiCache"
  metric_name         = "Evictions"
  dimensions          = { CacheClusterId = local.redis_node_ids[count.index] }
  statistic           = "Sum"
  period              = local.five_minutes
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}

############################
# NAT gateways (one alarm per gateway)
############################

resource "aws_cloudwatch_metric_alarm" "nat_port_allocation" {
  count = length(var.nat_gateway_ids)

  alarm_name          = "${local.prefix}-nat-port-allocation-${count.index}"
  alarm_description   = "NAT gateway ${var.nat_gateway_ids[count.index]} failed to allocate a source port"
  namespace           = "AWS/NATGateway"
  metric_name         = "ErrorPortAllocation"
  dimensions          = { NatGatewayId = var.nat_gateway_ids[count.index] }
  statistic           = "Sum"
  period              = local.five_minutes
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
}

############################
# Budget
############################

resource "aws_budgets_budget" "monthly" {
  count = local.budget_enabled ? 1 : 0

  name         = "${local.prefix}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = [80, 100]
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [var.alert_email]
    }
  }
}
