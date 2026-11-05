locals {
  prefix = "${var.project}-${var.environment}"
  cfg    = var.backend_config

  # The image has no .env files: every var the backend validates is set here. APP_NAME,
  # APP_DESCRIPTION and APP_VERSION keep their package.json defaults from the image.
  environment = {
    NODE_ENV = "production"

    APP_HOST                     = "0.0.0.0"
    APP_PORT                     = tostring(var.app_port)
    SHUTDOWN_DRAIN_MS            = tostring(local.cfg.shutdown_drain_ms)
    SHUTDOWN_INFLIGHT_TIMEOUT_MS = tostring(local.cfg.shutdown_inflight_timeout_ms)

    API_PREFIX                      = "api"
    API_ALLOWED_ORIGINS             = jsonencode(var.api_allowed_origins)
    API_ALLOWED_NON_BROWSER_ORIGINS = tostring(local.cfg.api_allowed_non_browser_origins)
    # One hop: the ALB. Without it every client shares the ALB address and one throttle bucket.
    TRUST_PROXY = "1"

    JWT_TTL = tostring(local.cfg.jwt_ttl)

    DATABASE_HOST = var.db_host
    DATABASE_PORT = var.db_port
    DATABASE_NAME = var.db_name
    DATABASE_USER = var.db_username
    # RDS enforces TLS (rds.force_ssl); the image trusts the RDS CA bundle via NODE_EXTRA_CA_CERTS.
    DATABASE_SSL                  = "true"
    DATABASE_POOL_MAX             = tostring(local.cfg.database_pool_max)
    DATABASE_CONNECT_TIMEOUT_MS   = tostring(local.cfg.database_connect_timeout_ms)
    DATABASE_STATEMENT_TIMEOUT_MS = tostring(local.cfg.database_statement_timeout_ms)
    DATABASE_FAIL_FAST            = tostring(local.cfg.database_fail_fast)
    DATABASE_LOG_LEVELS           = jsonencode(local.cfg.database_log_levels)

    # JSON lines for CloudWatch Logs.
    LOG_PRETTY            = "false"
    LOG_LEVEL             = local.cfg.log_level
    LOG_EXCLUDE_ENDPOINTS = jsonencode(local.cfg.log_exclude_endpoints)

    HEALTH_CHECK_TRIGGER_MS = tostring(local.cfg.health_check_trigger_ms)

    REDIS_ENABLED = "true"
    REDIS_HOST    = var.redis_host
    REDIS_PORT    = var.redis_port
    REDIS_TLS     = "true"

    # Sentry also needs SENTRY_DSN, injected from the app secret when enabled.
    SENTRY_ENABLED        = tostring(local.cfg.sentry_enabled)
    SENTRY_IGNORED_ERRORS = jsonencode(local.cfg.sentry_ignored_errors)

    # The backend never serves API docs in production; explicit for clarity.
    SWAGGER_ENABLED = "false"

    THROTTLE_ENABLED = tostring(local.cfg.throttle_enabled)
    THROTTLE_LIMIT   = tostring(local.cfg.throttle_limit)
    THROTTLE_TTL     = tostring(local.cfg.throttle_ttl)
  }

  container_environment = concat(
    [for name, value in local.environment : { name = name, value = value }],
    local.cfg.otel_exporter_otlp_endpoint == "" ? [] : [
      { name = "OTEL_EXPORTER_OTLP_ENDPOINT", value = local.cfg.otel_exporter_otlp_endpoint },
    ],
  )

  container_secrets = concat(
    [
      {
        name      = "DATABASE_PASSWORD"
        valueFrom = "${var.rds_secrets_arn}:password::"
      },
      {
        name      = "REDIS_PASSWORD"
        valueFrom = var.redis_auth_secret_arn
      },
      {
        name      = "JWT_SECRET"
        valueFrom = var.jwt_secret_arn
      },
    ],
    # Referenced only when enabled, so the app secret needs no SENTRY_DSN key otherwise.
    local.cfg.sentry_enabled ? [
      {
        name      = "SENTRY_DSN"
        valueFrom = "${var.app_secret_arn}:SENTRY_DSN::"
      },
    ] : [],
  )
}

resource "aws_ecs_task_definition" "app" {
  #checkov:skip=CKV_AWS_336: the Node image writes to its filesystem at runtime; a read-only root with tmpfs mounts is a separate hardening task
  family                   = "${local.prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = var.project
      image = "${var.repository_url}:${var.image_tag}"

      # By default the backend drains for 10s and then waits up to 20s for in-flight requests,
      # so 60s leaves headroom before ECS sends SIGKILL.
      stopTimeout = 60

      # NestJS and Prisma write to the filesystem at runtime (temp files, engine cache).
      readonlyRootFilesystem = false

      # Required by ECS Exec and reaps zombie processes.
      linuxParameters = {
        initProcessEnabled = true
      }

      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
        }
      ]

      environment = local.container_environment
      secrets     = local.container_secrets

      healthCheck = {
        command     = ["CMD", "node", "-e", "fetch('http://localhost:'+(process.env.APP_PORT||${var.app_port})+'/health/live').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs" {
  #checkov:skip=CKV_AWS_158: encrypted at rest with the CloudWatch Logs service key; a dedicated CMK for logs is not provisioned yet
  #checkov:skip=CKV_AWS_338: application logs are operational, not audit records; retention is set by var.log_retention_days to bound cost
  name              = "/ecs/${local.prefix}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "ecs_migration" {
  #checkov:skip=CKV_AWS_158: encrypted at rest with the CloudWatch Logs service key; a dedicated CMK for logs is not provisioned yet
  #checkov:skip=CKV_AWS_338: migration logs are operational, not audit records; retention is set by var.log_retention_days to bound cost
  name              = "/ecs/${local.prefix}-task-migration"
  retention_in_days = var.log_retention_days
}
