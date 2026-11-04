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
| [aws_acm_certificate.vpn_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_certificate_body"></a> [certificate\_body](#input\_certificate\_body) | Path to certificate body | `string` | n/a | yes |
| <a name="input_certificate_chain"></a> [certificate\_chain](#input\_certificate\_chain) | Path to certificate chain | `string` | n/a | yes |
| <a name="input_private_key"></a> [private\_key](#input\_private\_key) | Path to private key | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | n/a |
<!-- END_TF_DOCS -->