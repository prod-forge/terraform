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
| [aws_db_instance.postgres](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | DB Name | `string` | n/a | yes |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | DB Subnet Group Name | `string` | n/a | yes |
| <a name="input_rds_identifier"></a> [rds\_identifier](#input\_rds\_identifier) | RDS Identifier | `string` | n/a | yes |
| <a name="input_username"></a> [username](#input\_username) | DB Username | `string` | n/a | yes |
| <a name="input_vpc_security_group_id"></a> [vpc\_security\_group\_id](#input\_vpc\_security\_group\_id) | VPC Security Group ID | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_db_name"></a> [db\_name](#output\_db\_name) | n/a |
| <a name="output_host"></a> [host](#output\_host) | n/a |
| <a name="output_port"></a> [port](#output\_port) | n/a |
| <a name="output_secrets_arn"></a> [secrets\_arn](#output\_secrets\_arn) | n/a |
| <a name="output_username"></a> [username](#output\_username) | n/a |
<!-- END_TF_DOCS -->