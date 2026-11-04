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
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_secretsmanager_secret.prod_forge_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_secrets_manager_name"></a> [secrets\_manager\_name](#input\_secrets\_manager\_name) | Secrets Manager Name | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_kms_arn"></a> [kms\_arn](#output\_kms\_arn) | KMS ARN |
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | Secrets Manager ARN |
<!-- END_TF_DOCS -->