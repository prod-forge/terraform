<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

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
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Task CPU units | `number` | `256` | no |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | DB Host | `string` | n/a | yes |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | DB Table Name | `string` | n/a | yes |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | DB Port | `string` | n/a | yes |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | DB Username | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Image tag of the initial task definition revision; also exposed as APP\_VERSION | `string` | `"initial"` | no |
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
| <a name="output_task_definition_family"></a> [task\_definition\_family](#output\_task\_definition\_family) | n/a |
<!-- END_TF_DOCS -->