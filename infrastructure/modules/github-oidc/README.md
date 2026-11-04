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
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_backend_repo"></a> [backend\_repo](#input\_backend\_repo) | Repository allowed to assume the backend role | `string` | `"backend"` | no |
| <a name="input_create_oidc_provider"></a> [create\_oidc\_provider](#input\_create\_oidc\_provider) | Create the account-wide GitHub OIDC provider; false reads the existing one | `bool` | `true` | no |
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