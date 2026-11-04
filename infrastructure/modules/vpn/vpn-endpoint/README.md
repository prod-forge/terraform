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
| [aws_ec2_client_vpn_endpoint.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_client_vpn_certificate_arn"></a> [client\_vpn\_certificate\_arn](#input\_client\_vpn\_certificate\_arn) | Client VPN Certificate ARN | `string` | n/a | yes |
| <a name="input_server_vpn_certificate_arn"></a> [server\_vpn\_certificate\_arn](#input\_server\_vpn\_certificate\_arn) | Server VPN Certificate ARN | `string` | n/a | yes |
| <a name="input_sg_vpn_id"></a> [sg\_vpn\_id](#input\_sg\_vpn\_id) | Security Group VPN ID | `string` | n/a | yes |
| <a name="input_vpc_main_id"></a> [vpc\_main\_id](#input\_vpc\_main\_id) | VPC Main ID | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | n/a |
<!-- END_TF_DOCS -->