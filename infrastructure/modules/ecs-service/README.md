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
| [aws_ecs_service.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_iam_policy.ecs_deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ecs_passrole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_passrole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID | `string` | n/a | yes |
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | ECS Cluster ID | `string` | n/a | yes |
| <a name="input_ecs_task_definition_arn"></a> [ecs\_task\_definition\_arn](#input\_ecs\_task\_definition\_arn) | ECS Task Definition ARN | `string` | n/a | yes |
| <a name="input_github_actions_role_name"></a> [github\_actions\_role\_name](#input\_github\_actions\_role\_name) | IAM role name for GitHub Actions to attach ECS deploy policy | `string` | n/a | yes |
| <a name="input_lb_target_group_arn"></a> [lb\_target\_group\_arn](#input\_lb\_target\_group\_arn) | Load Balancer Target Group ARN | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project Name | `string` | n/a | yes |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Public subnet IDs | `list(string)` | n/a | yes |
| <a name="input_sg_ecs_id"></a> [sg\_ecs\_id](#input\_sg\_ecs\_id) | Security Group for ECS ID | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->