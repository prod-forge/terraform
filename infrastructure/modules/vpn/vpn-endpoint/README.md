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
| [aws_cloudwatch_log_group.connections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_stream.connections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream) | resource |
| [aws_ec2_client_vpn_endpoint.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_client_cidr_block"></a> [client\_cidr\_block](#input\_client\_cidr\_block) | CIDR block that VPN client addresses are assigned from; must not overlap the VPC CIDR | `string` | `"10.200.0.0/22"` | no |
| <a name="input_client_vpn_certificate_arn"></a> [client\_vpn\_certificate\_arn](#input\_client\_vpn\_certificate\_arn) | Client VPN Certificate ARN | `string` | n/a | yes |
| <a name="input_connection_log_retention_days"></a> [connection\_log\_retention\_days](#input\_connection\_log\_retention\_days) | Days to keep the Client VPN connection logs | `number` | `30` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, prod), used in resource names | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name, used in resource names | `string` | n/a | yes |
| <a name="input_server_vpn_certificate_arn"></a> [server\_vpn\_certificate\_arn](#input\_server\_vpn\_certificate\_arn) | Server VPN Certificate ARN | `string` | n/a | yes |
| <a name="input_sg_vpn_id"></a> [sg\_vpn\_id](#input\_sg\_vpn\_id) | Security Group VPN ID | `string` | n/a | yes |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block of the VPC; the VPN pushes its Amazon-provided DNS server (base address plus two) | `string` | n/a | yes |
| <a name="input_vpc_main_id"></a> [vpc\_main\_id](#input\_vpc\_main\_id) | VPC Main ID | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | n/a |
<!-- END_TF_DOCS -->