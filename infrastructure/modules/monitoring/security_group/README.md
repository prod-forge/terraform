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
| [aws_security_group.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_monitoring_egress_cidr_blocks"></a> [monitoring\_egress\_cidr\_blocks](#input\_monitoring\_egress\_cidr\_blocks) | CIDR blocks for egress traffic | `list(string)` | n/a | yes |
| <a name="input_monitoring_egress_from_port"></a> [monitoring\_egress\_from\_port](#input\_monitoring\_egress\_from\_port) | Start port for egress traffic | `number` | n/a | yes |
| <a name="input_monitoring_egress_protocol"></a> [monitoring\_egress\_protocol](#input\_monitoring\_egress\_protocol) | Protocol for egress traffic | `string` | n/a | yes |
| <a name="input_monitoring_egress_to_port"></a> [monitoring\_egress\_to\_port](#input\_monitoring\_egress\_to\_port) | End port for egress traffic | `number` | n/a | yes |
| <a name="input_monitoring_ingress_rules"></a> [monitoring\_ingress\_rules](#input\_monitoring\_ingress\_rules) | n/a | <pre>list(object({<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    cidr_blocks = list(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_sg_monitoring_id"></a> [sg\_monitoring\_id](#output\_sg\_monitoring\_id) | n/a |
<!-- END_TF_DOCS -->