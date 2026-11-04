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
| [aws_lb.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_project"></a> [project](#input\_project) | Project Name | `string` | n/a | yes |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Public subnet IDs | `list(string)` | n/a | yes |
| <a name="input_sg_alb_id"></a> [sg\_alb\_id](#input\_sg\_alb\_id) | Security Group for Load Balancer ID | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_lb_arn_suffix"></a> [lb\_arn\_suffix](#output\_lb\_arn\_suffix) | n/a |
| <a name="output_lb_listener"></a> [lb\_listener](#output\_lb\_listener) | n/a |
| <a name="output_lb_target_group_arn"></a> [lb\_target\_group\_arn](#output\_lb\_target\_group\_arn) | n/a |
| <a name="output_lb_target_group_arn_suffix"></a> [lb\_target\_group\_arn\_suffix](#output\_lb\_target\_group\_arn\_suffix) | n/a |
<!-- END_TF_DOCS -->