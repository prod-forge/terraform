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
| [aws_service_discovery_private_dns_namespace.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_service_discovery_service.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_project"></a> [project](#input\_project) | Project name; the private DNS namespace is <project>.local | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC the private DNS namespace is attached to | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backend_service_arn"></a> [backend\_service\_arn](#output\_backend\_service\_arn) | Cloud Map service ARN the backend ECS service registers in |
| <a name="output_namespace_name"></a> [namespace\_name](#output\_namespace\_name) | Private DNS namespace name |
<!-- END_TF_DOCS -->
