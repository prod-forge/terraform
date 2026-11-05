# Offline plan-only tests for the backend task definition. The image has no
# .env files, so the task definition must carry every config var the backend
# validates; secrets come from Secrets Manager, never from plain env.

mock_provider "aws" {}

variables {
  project     = "prod-forge-test"
  environment = "dev"
  region      = "eu-central-1"

  repository_url          = "123456789012.dkr.ecr.eu-central-1.amazonaws.com/prod-forge-test-dev"
  task_execution_role_arn = "arn:aws:iam::123456789012:role/execution"
  task_role_arn           = "arn:aws:iam::123456789012:role/task"

  rds_secrets_arn       = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:rds-master"
  redis_auth_secret_arn = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:redis-auth"
  jwt_secret_arn        = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:jwt"
  app_secret_arn        = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:app-config"

  db_name     = "todolist"
  db_username = "app"
  db_host     = "db.example.internal"
  db_port     = "5432"
  redis_host  = "redis.example.internal"
  redis_port  = "6379"

  api_allowed_origins = ["https://example.com", "https://d111111abcdef8.cloudfront.net"]
}

############################
# Negative cases
############################

run "rejects_shutdown_longer_than_stop_timeout" {
  command = plan

  module {
    source = "../../modules/task_definition"
  }

  variables {
    backend_config = {
      shutdown_drain_ms            = 30000
      shutdown_inflight_timeout_ms = 30000
    }
  }

  expect_failures = [var.backend_config]
}

run "rejects_unknown_log_level" {
  command = plan

  module {
    source = "../../modules/task_definition"
  }

  variables {
    backend_config = {
      log_level = "verbose"
    }
  }

  expect_failures = [var.backend_config]
}

############################
# Positive cases
############################

run "carries_every_backend_config_var_with_backend_defaults" {
  command = plan

  module {
    source = "../../modules/task_definition"
  }

  # Overrides the prod terraform.tfvars value that terraform test also loads.
  variables {
    backend_config = {}
  }

  assert {
    condition = setunion(
      toset([for e in jsondecode(aws_ecs_task_definition.app.container_definitions)[0].environment : e.name]),
      toset([for s in jsondecode(aws_ecs_task_definition.app.container_definitions)[0].secrets : s.name]),
      ) == toset([
        "NODE_ENV", "APP_HOST", "APP_PORT", "SHUTDOWN_DRAIN_MS", "SHUTDOWN_INFLIGHT_TIMEOUT_MS",
        "API_PREFIX", "API_ALLOWED_ORIGINS", "API_ALLOWED_NON_BROWSER_ORIGINS", "TRUST_PROXY",
        "JWT_SECRET", "JWT_TTL",
        "DATABASE_HOST", "DATABASE_PORT", "DATABASE_NAME", "DATABASE_USER", "DATABASE_PASSWORD", "DATABASE_SSL",
        "DATABASE_POOL_MAX", "DATABASE_CONNECT_TIMEOUT_MS", "DATABASE_STATEMENT_TIMEOUT_MS", "DATABASE_FAIL_FAST",
        "DATABASE_LOG_LEVELS",
        "LOG_LEVEL", "LOG_PRETTY", "LOG_EXCLUDE_ENDPOINTS",
        "HEALTH_CHECK_TRIGGER_MS",
        "REDIS_HOST", "REDIS_PORT", "REDIS_TLS", "REDIS_PASSWORD",
        "SENTRY_ENABLED", "SENTRY_IGNORED_ERRORS",
        "SWAGGER_ENABLED",
        "THROTTLE_ENABLED", "THROTTLE_LIMIT", "THROTTLE_TTL",
    ])
    error_message = "The task definition must set every backend config var (APP_NAME, APP_DESCRIPTION and APP_VERSION come from the image)."
  }

  assert {
    condition = toset([for s in jsondecode(aws_ecs_task_definition.app.container_definitions)[0].secrets : s.name]) == toset([
      "DATABASE_PASSWORD", "REDIS_PASSWORD", "JWT_SECRET",
    ])
    error_message = "Without Sentry only the database password, Redis AUTH token and JWT secret are secrets."
  }

  assert {
    condition = {
      for e in jsondecode(aws_ecs_task_definition.app.container_definitions)[0].environment : e.name => e.value
      if contains(["JWT_TTL", "THROTTLE_ENABLED", "THROTTLE_LIMIT", "THROTTLE_TTL", "SHUTDOWN_DRAIN_MS", "SHUTDOWN_INFLIGHT_TIMEOUT_MS", "DATABASE_POOL_MAX", "LOG_LEVEL", "SENTRY_ENABLED", "DATABASE_LOG_LEVELS"], e.name)
      } == {
      JWT_TTL                      = "3600"
      THROTTLE_ENABLED             = "true"
      THROTTLE_LIMIT               = "60"
      THROTTLE_TTL                 = "60000"
      SHUTDOWN_DRAIN_MS            = "10000"
      SHUTDOWN_INFLIGHT_TIMEOUT_MS = "20000"
      DATABASE_POOL_MAX            = "10"
      LOG_LEVEL                    = "info"
      SENTRY_ENABLED               = "false"
      DATABASE_LOG_LEVELS          = "[]"
    }
    error_message = "Tunable defaults must match the backend defaults."
  }

  assert {
    condition = {
      for e in jsondecode(aws_ecs_task_definition.app.container_definitions)[0].environment : e.name => e.value
      if contains(["NODE_ENV", "TRUST_PROXY", "DATABASE_SSL", "REDIS_TLS", "LOG_PRETTY", "SWAGGER_ENABLED", "APP_PORT", "API_ALLOWED_ORIGINS"], e.name)
      } == {
      NODE_ENV            = "production"
      TRUST_PROXY         = "1"
      DATABASE_SSL        = "true"
      REDIS_TLS           = "true"
      LOG_PRETTY          = "false"
      SWAGGER_ENABLED     = "false"
      APP_PORT            = "3000"
      API_ALLOWED_ORIGINS = "[\"https://example.com\",\"https://d111111abcdef8.cloudfront.net\"]"
    }
    error_message = "Deployment values: one proxy hop (ALB), TLS to RDS and Redis, JSON logs, no API docs, CORS for the web client origins."
  }
}

run "sentry_and_tracing_are_opt_in" {
  command = plan

  module {
    source = "../../modules/task_definition"
  }

  variables {
    backend_config = {
      sentry_enabled              = true
      otel_exporter_otlp_endpoint = "http://tempo.example.internal:4318"
    }
  }

  assert {
    condition = one([
      for s in jsondecode(aws_ecs_task_definition.app.container_definitions)[0].secrets : s.valueFrom if s.name == "SENTRY_DSN"
    ]) == "arn:aws:secretsmanager:eu-central-1:123456789012:secret:app-config:SENTRY_DSN::"
    error_message = "With Sentry enabled SENTRY_DSN must come from the SENTRY_DSN key of the app config secret."
  }

  assert {
    condition = {
      for e in jsondecode(aws_ecs_task_definition.app.container_definitions)[0].environment : e.name => e.value
      if contains(["SENTRY_ENABLED", "OTEL_EXPORTER_OTLP_ENDPOINT"], e.name)
      } == {
      SENTRY_ENABLED              = "true"
      OTEL_EXPORTER_OTLP_ENDPOINT = "http://tempo.example.internal:4318"
    }
    error_message = "SENTRY_ENABLED and the OTLP endpoint must follow backend_config."
  }
}

# The stack and the environment roots pass backend_config through with optional
# attributes that are null when omitted; the module defaults must still apply.
run "null_attributes_fall_back_to_backend_defaults" {
  command = plan

  module {
    source = "../../modules/task_definition"
  }

  variables {
    backend_config = {
      log_level      = null
      throttle_limit = 100
    }
  }

  assert {
    condition = {
      for e in jsondecode(aws_ecs_task_definition.app.container_definitions)[0].environment : e.name => e.value
      if contains(["LOG_LEVEL", "THROTTLE_LIMIT"], e.name)
    } == { LOG_LEVEL = "info", THROTTLE_LIMIT = "100" }
    error_message = "Null attributes must use the backend default; set attributes must override it."
  }
}
