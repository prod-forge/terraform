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
| [aws_security_group.alb_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ecs_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.rds_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.redis_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.vpn_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_sg_alb_id"></a> [sg\_alb\_id](#output\_sg\_alb\_id) | n/a |
| <a name="output_sg_ecs_id"></a> [sg\_ecs\_id](#output\_sg\_ecs\_id) | n/a |
| <a name="output_sg_rds_id"></a> [sg\_rds\_id](#output\_sg\_rds\_id) | n/a |
| <a name="output_sg_redis_id"></a> [sg\_redis\_id](#output\_sg\_redis\_id) | n/a |
| <a name="output_sg_vpn_id"></a> [sg\_vpn\_id](#output\_sg\_vpn\_id) | n/a |
<!-- END_TF_DOCS -->