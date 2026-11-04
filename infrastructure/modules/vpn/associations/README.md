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
| [aws_ec2_client_vpn_network_association.vpn_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_network_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID | `string` | n/a | yes |
| <a name="input_vpn_endpoint_id"></a> [vpn\_endpoint\_id](#input\_vpn\_endpoint\_id) | VPN Endpoint ID | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->