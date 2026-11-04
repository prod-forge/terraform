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
| [aws_iam_policy.secrets_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_task_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_secret_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_app_secret_arn"></a> [app\_secret\_arn](#input\_app\_secret\_arn) | Manually filled application config secret ARN (SENTRY\_DSN) | `string` | n/a | yes |
| <a name="input_db_secret_arn"></a> [db\_secret\_arn](#input\_db\_secret\_arn) | ARN of the RDS-managed master user secret | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, prod), used in resource names | `string` | n/a | yes |
| <a name="input_jwt_secret_arn"></a> [jwt\_secret\_arn](#input\_jwt\_secret\_arn) | JWT signing secret ARN | `string` | n/a | yes |
| <a name="input_kms_arn"></a> [kms\_arn](#input\_kms\_arn) | KMS ARN | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name, used in resource names | `string` | n/a | yes |
| <a name="input_redis_auth_secret_arn"></a> [redis\_auth\_secret\_arn](#input\_redis\_auth\_secret\_arn) | Redis AUTH token secret ARN | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_task_execution_role_arn"></a> [task\_execution\_role\_arn](#output\_task\_execution\_role\_arn) | n/a |
| <a name="output_task_role_arn"></a> [task\_role\_arn](#output\_task\_role\_arn) | n/a |
<!-- END_TF_DOCS -->