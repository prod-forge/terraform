variable "repository_url" {
  description = "Repository URL"
  type        = string
}

variable "task_execution_role_arn" {
  description = "IAM Task Execution Role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "IAM Task Role ARN"
  type        = string
}

variable "rds_secrets_arn" {
  description = "RDS Secrets ARN"
  type        = string
}

variable "db_name" {
  description = "DB Table Name"
  type        = string
}

variable "db_username" {
  description = "DB Username"
  type        = string
}

variable "db_host" {
  description = "DB Host"
  type        = string
}

variable "db_port" {
  description = "DB Port"
  type        = string
}

variable "redis_host" {
  description = "Redis Host"
  type        = string
}

variable "redis_port" {
  description = "Redis Port"
  type        = string
}

variable "project" {
  description = "Project Name"
  type        = string
}

variable "redis_auth_secret_arn" {
  description = "Redis AUTH token secret ARN"
  type        = string
}

variable "jwt_secret_arn" {
  description = "JWT signing secret ARN"
  type        = string
}

variable "region" {
  description = "AWS region for the awslogs driver"
  type        = string
}

variable "image_tag" {
  description = "Image tag of the initial task definition revision; CD replaces the image afterwards"
  type        = string
  default     = "initial"
}

variable "cpu" {
  description = "Task CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory (MiB)"
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "CloudWatch retention for application and migration logs"
  type        = number
  default     = 7
}

variable "environment" {
  description = "Environment name (dev, prod), used in resource names"
  type        = string
}

variable "app_secret_arn" {
  description = "ARN of the manually filled application secret; its SENTRY_DSN key is read when Sentry is enabled"
  type        = string
}

variable "api_allowed_origins" {
  description = "Browser origins allowed by CORS (API_ALLOWED_ORIGINS), for example the web client domain and its CloudFront domain"
  type        = list(string)
}

# Defaults match the backend defaults in src/config/*.config.ts; null attributes fall back to them.
variable "backend_config" {
  description = "Backend tunables rendered into the task environment (see guide/workflow.md for the variable map)"
  type = object({
    log_level                       = optional(string, "info")
    log_exclude_endpoints           = optional(list(string), [])
    database_log_levels             = optional(list(string), [])
    database_pool_max               = optional(number, 10)
    database_connect_timeout_ms     = optional(number, 5000)
    database_statement_timeout_ms   = optional(number, 5000)
    database_fail_fast              = optional(bool, true)
    jwt_ttl                         = optional(number, 3600)
    throttle_enabled                = optional(bool, true)
    throttle_limit                  = optional(number, 60)
    throttle_ttl                    = optional(number, 60000)
    shutdown_drain_ms               = optional(number, 10000)
    shutdown_inflight_timeout_ms    = optional(number, 20000)
    health_check_trigger_ms         = optional(number, 15000)
    api_allowed_non_browser_origins = optional(bool, true)
    sentry_enabled                  = optional(bool, false)
    sentry_ignored_errors           = optional(list(string), [])
    otel_exporter_otlp_endpoint     = optional(string, "")
  })
  default = {}

  validation {
    condition     = contains(["error", "warn", "info", "trace"], var.backend_config.log_level)
    error_message = "log_level must be one of error, warn, info, trace (backend LogLevelEnum)."
  }

  validation {
    condition     = alltrue([for l in var.backend_config.database_log_levels : contains(["info", "query", "warn", "error"], l)])
    error_message = "database_log_levels may contain only info, query, warn and error."
  }

  # Both shutdown phases must finish before ECS sends SIGKILL (stopTimeout = 60 s).
  validation {
    condition     = var.backend_config.shutdown_drain_ms + var.backend_config.shutdown_inflight_timeout_ms < 60000
    error_message = "shutdown_drain_ms + shutdown_inflight_timeout_ms must be below the 60 s stopTimeout."
  }
}

variable "app_port" {
  description = "Port the backend container listens on"
  type        = number
  default     = 3000
}
