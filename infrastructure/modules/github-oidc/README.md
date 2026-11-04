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
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_backend_repo"></a> [backend\_repo](#input\_backend\_repo) | Repository allowed to assume the backend role | `string` | `"backend"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment used in role names | `string` | n/a | yes |
| <a name="input_frontend_repo"></a> [frontend\_repo](#input\_frontend\_repo) | Repository allowed to assume the frontend role | `string` | `"frontend"` | no |
| <a name="input_github_environment"></a> [github\_environment](#input\_github\_environment) | GitHub environment name that deploy jobs run in | `string` | `"prod"` | no |
| <a name="input_github_owner"></a> [github\_owner](#input\_github\_owner) | GitHub organization or user | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name used in role names | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backend_role_arn"></a> [backend\_role\_arn](#output\_backend\_role\_arn) | ARN of the IAM role assumed by the backend repository |
| <a name="output_backend_role_name"></a> [backend\_role\_name](#output\_backend\_role\_name) | Name of the IAM role assumed by the backend repository |
| <a name="output_frontend_role_arn"></a> [frontend\_role\_arn](#output\_frontend\_role\_arn) | ARN of the IAM role assumed by the frontend repository |
| <a name="output_frontend_role_name"></a> [frontend\_role\_name](#output\_frontend\_role\_name) | Name of the IAM role assumed by the frontend repository |
<!-- END_TF_DOCS -->