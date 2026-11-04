<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_secretsmanager_secret.grafana_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.jwt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.prod_forge_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.redis_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.grafana_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.jwt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.redis_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [random_password.grafana_admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.jwt](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.redis](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, used in generated secret names | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name, used in generated secret names | `string` | n/a | yes |
| <a name="input_secrets_manager_name"></a> [secrets\_manager\_name](#input\_secrets\_manager\_name) | Secrets Manager Name | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_grafana_admin_secret_arn"></a> [grafana\_admin\_secret\_arn](#output\_grafana\_admin\_secret\_arn) | Grafana admin password secret ARN |
| <a name="output_jwt_secret_arn"></a> [jwt\_secret\_arn](#output\_jwt\_secret\_arn) | JWT signing secret ARN |
| <a name="output_kms_arn"></a> [kms\_arn](#output\_kms\_arn) | KMS ARN |
| <a name="output_redis_auth_secret_arn"></a> [redis\_auth\_secret\_arn](#output\_redis\_auth\_secret\_arn) | Redis AUTH token secret ARN |
| <a name="output_redis_auth_token"></a> [redis\_auth\_token](#output\_redis\_auth\_token) | Redis AUTH token |
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | Secrets Manager ARN |
<!-- END_TF_DOCS -->