# Offline plan-only tests for the alarms module. The run targets the module
# directly because the root reads git-ignored VPN key files with file().

mock_provider "aws" {}

variables {
  project     = "prod-forge-test"
  environment = "dev"

  ecs_cluster_name           = "prod-forge-test-cluster"
  ecs_service_name           = "prod-forge-test-service"
  lb_arn_suffix              = "app/test/0123456789abcdef"
  lb_target_group_arn_suffix = "targetgroup/test/0123456789abcdef"
  rds_identifier             = "prod-forge-test-database"
  redis_replication_group_id = "prod-forge-test-redis"
  redis_num_cache_clusters   = 2
  nat_gateway_ids            = ["nat-0123456789abcdef0", "nat-0123456789abcdef1"]
}

############################
# Negative cases
############################

run "alarms_rejects_negative_budget" {
  command = plan

  module {
    source = "../../modules/alarms"
  }

  variables {
    monthly_budget_usd = -1
  }

  expect_failures = [var.monthly_budget_usd]
}

run "alarms_without_email_creates_no_subscription_or_budget" {
  command = plan

  module {
    source = "../../modules/alarms"
  }

  variables {
    alert_email        = ""
    monthly_budget_usd = 400
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email) == 0
    error_message = "An empty alert_email must not create a subscription."
  }

  assert {
    condition     = length(aws_budgets_budget.monthly) == 0
    error_message = "A budget without a subscriber email must not be created."
  }
}

run "alarms_without_budget_amount_creates_no_budget" {
  command = plan

  module {
    source = "../../modules/alarms"
  }

  variables {
    alert_email        = "ops@example.com"
    monthly_budget_usd = 0
  }

  assert {
    condition     = length(aws_budgets_budget.monthly) == 0
    error_message = "monthly_budget_usd = 0 must disable the budget."
  }
}

############################
# Positive cases
############################

run "alarms_cover_every_signal" {
  command = plan

  module {
    source = "../../modules/alarms"
  }

  variables {
    alert_email        = "ops@example.com"
    monthly_budget_usd = 400
  }

  assert {
    condition = (
      1 + 1 + 3 + 3 +
      length(aws_cloudwatch_metric_alarm.redis_cpu) +
      length(aws_cloudwatch_metric_alarm.redis_evictions) +
      length(aws_cloudwatch_metric_alarm.nat_port_allocation)
    ) == 14
    error_message = "Expected 2 ECS, 3 ALB, 3 RDS, 2x2 Redis and 2 NAT alarms (14)."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.redis_cpu) == 2 && length(aws_cloudwatch_metric_alarm.redis_evictions) == 2
    error_message = "Redis alarms must exist once per node."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.nat_port_allocation) == 2
    error_message = "NAT port allocation alarms must exist once per gateway."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_connections.threshold == 320
    error_message = "The default connections threshold is 320."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_latency_p95.extended_statistic == "p95" && aws_cloudwatch_metric_alarm.alb_latency_p95.threshold == 0.5
    error_message = "Latency alarm must use p95 with a 0.5 s threshold."
  }
}

run "alarms_subscribe_email_and_create_budget" {
  command = plan

  module {
    source = "../../modules/alarms"
  }

  variables {
    alert_email        = "ops@example.com"
    monthly_budget_usd = 400
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email) == 1 && aws_sns_topic_subscription.email[0].protocol == "email" && aws_sns_topic_subscription.email[0].endpoint == "ops@example.com"
    error_message = "Expected one email subscription for alert_email."
  }

  assert {
    condition     = length(aws_budgets_budget.monthly) == 1 && aws_budgets_budget.monthly[0].limit_amount == "400" && aws_budgets_budget.monthly[0].time_unit == "MONTHLY"
    error_message = "Expected a 400 USD monthly budget."
  }

  assert {
    condition     = length(aws_budgets_budget.monthly[0].notification) == 2
    error_message = "Budget must notify at 80% and 100%."
  }
}

run "alarms_scale_with_nat_gateways_and_redis_nodes" {
  command = plan

  module {
    source = "../../modules/alarms"
  }

  variables {
    nat_gateway_ids          = ["nat-0123456789abcdef0"]
    redis_num_cache_clusters = 3
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.nat_port_allocation) == 1
    error_message = "A single NAT gateway must produce one alarm."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.redis_cpu) == 3 && length(aws_cloudwatch_metric_alarm.redis_evictions) == 3
    error_message = "Three Redis nodes must produce three alarms per metric."
  }
}
