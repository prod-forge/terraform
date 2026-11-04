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
| [aws_appautoscaling_policy.cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.requests](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_ecs_service.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_iam_policy.ecs_deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ecs_passrole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_passrole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID | `string` | n/a | yes |
| <a name="input_backend_role_name"></a> [backend\_role\_name](#input\_backend\_role\_name) | Backend GitHub Actions role that receives the ECS deploy policy | `string` | n/a | yes |
| <a name="input_cpu_target_value"></a> [cpu\_target\_value](#input\_cpu\_target\_value) | Target average CPU utilization (percent) for the service | `number` | `60` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Initial number of tasks; afterwards Application Auto Scaling owns it | `number` | `1` | no |
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | ECS Cluster ID | `string` | n/a | yes |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | ECS Cluster name | `string` | n/a | yes |
| <a name="input_ecs_task_definition_arn"></a> [ecs\_task\_definition\_arn](#input\_ecs\_task\_definition\_arn) | ECS Task Definition ARN | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, prod), used in resource names | `string` | n/a | yes |
| <a name="input_lb_arn_suffix"></a> [lb\_arn\_suffix](#input\_lb\_arn\_suffix) | ALB ARN suffix, used by the ALBRequestCountPerTarget scaling metric | `string` | n/a | yes |
| <a name="input_lb_target_group_arn"></a> [lb\_target\_group\_arn](#input\_lb\_target\_group\_arn) | Load Balancer Target Group ARN | `string` | n/a | yes |
| <a name="input_lb_target_group_arn_suffix"></a> [lb\_target\_group\_arn\_suffix](#input\_lb\_target\_group\_arn\_suffix) | Target group ARN suffix, used by the ALBRequestCountPerTarget scaling metric | `string` | n/a | yes |
| <a name="input_max_capacity"></a> [max\_capacity](#input\_max\_capacity) | Maximum number of tasks auto scaling may run | `number` | `2` | no |
| <a name="input_migration_task_definition_family"></a> [migration\_task\_definition\_family](#input\_migration\_task\_definition\_family) | Family of the one-off migration task definition registered by the backend CD | `string` | n/a | yes |
| <a name="input_min_capacity"></a> [min\_capacity](#input\_min\_capacity) | Minimum number of tasks kept by auto scaling | `number` | `1` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnet IDs for the service tasks | `list(string)` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project Name | `string` | n/a | yes |
| <a name="input_requests_per_target_value"></a> [requests\_per\_target\_value](#input\_requests\_per\_target\_value) | Target ALB request count per task per minute | `number` | `1000` | no |
| <a name="input_service_discovery_arn"></a> [service\_discovery\_arn](#input\_service\_discovery\_arn) | Cloud Map service ARN to register tasks in; null disables service discovery | `string` | `null` | no |
| <a name="input_sg_ecs_id"></a> [sg\_ecs\_id](#input\_sg\_ecs\_id) | Security Group for ECS ID | `string` | n/a | yes |
| <a name="input_task_definition_family"></a> [task\_definition\_family](#input\_task\_definition\_family) | Family of the application task definition, used to scope the CD policy | `string` | n/a | yes |
| <a name="input_task_role_arns"></a> [task\_role\_arns](#input\_task\_role\_arns) | Task and task execution role ARNs the backend CD may pass to ECS | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | ECS service name |
<!-- END_TF_DOCS -->