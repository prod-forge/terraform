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
| [aws_db_parameter_group.postgres](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_iam_role.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.monitoring_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | Initial storage in GiB | `number` | `20` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Apply changes immediately instead of in the maintenance window | `bool` | `false` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | Automated backup retention in days (PITR window) | `number` | `1` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | Daily UTC backup window | `string` | `"03:00-04:00"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | DB Name | `string` | n/a | yes |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | DB Subnet Group Name | `string` | n/a | yes |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Block deletion of the instance | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name, used in the final snapshot identifier | `string` | n/a | yes |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | DB instance class | `string` | `"db.t4g.micro"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key ARN for storage, Performance Insights and the master user secret | `string` | n/a | yes |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Weekly UTC maintenance window | `string` | `"sun:04:30-sun:05:30"` | no |
| <a name="input_max_allocated_storage"></a> [max\_allocated\_storage](#input\_max\_allocated\_storage) | Storage autoscaling limit in GiB | `number` | `100` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Deploy a standby in a second Availability Zone | `bool` | `false` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name, used in the final snapshot identifier | `string` | n/a | yes |
| <a name="input_rds_identifier"></a> [rds\_identifier](#input\_rds\_identifier) | RDS Identifier | `string` | n/a | yes |
| <a name="input_username"></a> [username](#input\_username) | DB Username | `string` | n/a | yes |
| <a name="input_vpc_security_group_id"></a> [vpc\_security\_group\_id](#input\_vpc\_security\_group\_id) | VPC Security Group ID | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_db_name"></a> [db\_name](#output\_db\_name) | n/a |
| <a name="output_host"></a> [host](#output\_host) | n/a |
| <a name="output_identifier"></a> [identifier](#output\_identifier) | DB instance identifier (CloudWatch DBInstanceIdentifier) |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | n/a |
| <a name="output_port"></a> [port](#output\_port) | n/a |
| <a name="output_secrets_arn"></a> [secrets\_arn](#output\_secrets\_arn) | n/a |
| <a name="output_username"></a> [username](#output\_username) | n/a |
<!-- END_TF_DOCS -->