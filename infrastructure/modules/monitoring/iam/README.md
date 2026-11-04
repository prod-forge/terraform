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
| [aws_iam_instance_profile.ec2_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.secrets_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.ec2_ecr_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.ec2_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.observability_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_grafana_admin_secret_arn"></a> [grafana\_admin\_secret\_arn](#input\_grafana\_admin\_secret\_arn) | Secrets Manager ARN of the Grafana admin credentials; empty grants no access | `string` | `""` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS Key ARN | `string` | n/a | yes |
| <a name="input_observability_config_bucket_arn"></a> [observability\_config\_bucket\_arn](#input\_observability\_config\_bucket\_arn) | S3 bucket ARN holding the observability stack configuration; empty grants no access | `string` | `""` | no |
| <a name="input_secret_arn"></a> [secret\_arn](#input\_secret\_arn) | Secrets Manager ARN | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_monitoring_ec2_instance_profile_name"></a> [monitoring\_ec2\_instance\_profile\_name](#output\_monitoring\_ec2\_instance\_profile\_name) | n/a |
<!-- END_TF_DOCS -->