<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.35 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.35 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.ecs_migration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_task_definition.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_api_allowed_origins"></a> [api\_allowed\_origins](#input\_api\_allowed\_origins) | Browser origins allowed by CORS (API\_ALLOWED\_ORIGINS), for example the web client domain and its CloudFront domain | `list(string)` | n/a | yes |
| <a name="input_app_secret_arn"></a> [app\_secret\_arn](#input\_app\_secret\_arn) | ARN of the manually filled application secret; its SENTRY\_DSN key is read when Sentry is enabled | `string` | n/a | yes |
| <a name="input_backend_config"></a> [backend\_config](#input\_backend\_config) | Backend tunables rendered into the task environment (see docs/workflow.md for the variable map) | <pre>object({<br/>    log_level                       = optional(string, "info")<br/>    log_exclude_endpoints           = optional(list(string), [])<br/>    database_log_levels             = optional(list(string), [])<br/>    database_pool_max               = optional(number, 10)<br/>    database_connect_timeout_ms     = optional(number, 5000)<br/>    database_statement_timeout_ms   = optional(number, 5000)<br/>    database_fail_fast              = optional(bool, true)<br/>    jwt_ttl                         = optional(number, 3600)<br/>    throttle_enabled                = optional(bool, true)<br/>    throttle_limit                  = optional(number, 60)<br/>    throttle_ttl                    = optional(number, 60000)<br/>    shutdown_drain_ms               = optional(number, 10000)<br/>    shutdown_inflight_timeout_ms    = optional(number, 20000)<br/>    health_check_trigger_ms         = optional(number, 15000)<br/>    api_allowed_non_browser_origins = optional(bool, true)<br/>    sentry_enabled                  = optional(bool, false)<br/>    sentry_ignored_errors           = optional(list(string), [])<br/>    otel_exporter_otlp_endpoint     = optional(string, "")<br/>  })</pre> | `{}` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Task CPU units | `number` | `256` | no |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | DB Host | `string` | n/a | yes |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | DB Table Name | `string` | n/a | yes |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | DB Port | `string` | n/a | yes |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | DB Username | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, prod), used in resource names | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Image tag of the initial task definition revision; CD replaces the image afterwards | `string` | `"initial"` | no |
| <a name="input_jwt_secret_arn"></a> [jwt\_secret\_arn](#input\_jwt\_secret\_arn) | JWT signing secret ARN | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch retention for application and migration logs | `number` | `7` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Task memory (MiB) | `number` | `512` | no |
| <a name="input_project"></a> [project](#input\_project) | Project Name | `string` | n/a | yes |
| <a name="input_rds_secrets_arn"></a> [rds\_secrets\_arn](#input\_rds\_secrets\_arn) | RDS Secrets ARN | `string` | n/a | yes |
| <a name="input_redis_auth_secret_arn"></a> [redis\_auth\_secret\_arn](#input\_redis\_auth\_secret\_arn) | Redis AUTH token secret ARN | `string` | n/a | yes |
| <a name="input_redis_host"></a> [redis\_host](#input\_redis\_host) | Redis Host | `string` | n/a | yes |
| <a name="input_redis_port"></a> [redis\_port](#input\_redis\_port) | Redis Port | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the awslogs driver | `string` | n/a | yes |
| <a name="input_repository_url"></a> [repository\_url](#input\_repository\_url) | Repository URL | `string` | n/a | yes |
| <a name="input_task_execution_role_arn"></a> [task\_execution\_role\_arn](#input\_task\_execution\_role\_arn) | IAM Task Execution Role ARN | `string` | n/a | yes |
| <a name="input_task_role_arn"></a> [task\_role\_arn](#input\_task\_role\_arn) | IAM Task Role ARN | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ecs_task_definition_arn"></a> [ecs\_task\_definition\_arn](#output\_ecs\_task\_definition\_arn) | n/a |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | CloudWatch log group of the application task |
| <a name="output_migration_log_group_name"></a> [migration\_log\_group\_name](#output\_migration\_log\_group\_name) | CloudWatch log group of the migration task that backend CD registers |
| <a name="output_task_definition_family"></a> [task\_definition\_family](#output\_task\_definition\_family) | n/a |
<!-- END_TF_DOCS -->