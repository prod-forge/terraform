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
| [aws_instance.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_ssm_parameter.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_grafana_admin_secret_arn"></a> [grafana\_admin\_secret\_arn](#input\_grafana\_admin\_secret\_arn) | Secrets Manager ARN of the Grafana admin password | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type of the monitoring host | `string` | `"t3.small"` | no |
| <a name="input_monitoring_ec2_instance_profile_name"></a> [monitoring\_ec2\_instance\_profile\_name](#input\_monitoring\_ec2\_instance\_profile\_name) | IAM Monitoring Instance Profile Name | `string` | n/a | yes |
| <a name="input_observability_bucket"></a> [observability\_bucket](#input\_observability\_bucket) | S3 bucket holding the observability stack configuration | `string` | n/a | yes |
| <a name="input_public_subnet_id"></a> [public\_subnet\_id](#input\_public\_subnet\_id) | Public Subnet ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_repository_url"></a> [repository\_url](#input\_repository\_url) | ECR URL | `string` | n/a | yes |
| <a name="input_secret_id"></a> [secret\_id](#input\_secret\_id) | Secrets Manager secret ARN or name for the monitoring EC2 | `string` | n/a | yes |
| <a name="input_sg_monitoring_id"></a> [sg\_monitoring\_id](#input\_sg\_monitoring\_id) | Security Group Monitoring ID | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->