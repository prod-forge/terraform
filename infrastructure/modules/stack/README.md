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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_alarms"></a> [alarms](#module\_alarms) | ../alarms | n/a |
| <a name="module_api_certificate"></a> [api\_certificate](#module\_api\_certificate) | ../acm-certificate | n/a |
| <a name="module_client_vpn_certificate"></a> [client\_vpn\_certificate](#module\_client\_vpn\_certificate) | ../vpn/certificates/client | n/a |
| <a name="module_cloudfront_certificate"></a> [cloudfront\_certificate](#module\_cloudfront\_certificate) | ../acm-certificate | n/a |
| <a name="module_dns"></a> [dns](#module\_dns) | ../dns | n/a |
| <a name="module_ecr"></a> [ecr](#module\_ecr) | ../ecr | n/a |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | ../ecs-cluster | n/a |
| <a name="module_ecs_service"></a> [ecs\_service](#module\_ecs\_service) | ../ecs-service | n/a |
| <a name="module_frontend"></a> [frontend](#module\_frontend) | ../frontend | n/a |
| <a name="module_github_oidc"></a> [github\_oidc](#module\_github\_oidc) | ../github-oidc | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ../iam | n/a |
| <a name="module_load_balancer"></a> [load\_balancer](#module\_load\_balancer) | ../load_balancer | n/a |
| <a name="module_logs_bucket"></a> [logs\_bucket](#module\_logs\_bucket) | ../logs-bucket | n/a |
| <a name="module_monitoring_ec2"></a> [monitoring\_ec2](#module\_monitoring\_ec2) | ../monitoring/ec2 | n/a |
| <a name="module_monitoring_iam"></a> [monitoring\_iam](#module\_monitoring\_iam) | ../monitoring/iam | n/a |
| <a name="module_monitoring_sg"></a> [monitoring\_sg](#module\_monitoring\_sg) | ../monitoring/security_group | n/a |
| <a name="module_observability_config"></a> [observability\_config](#module\_observability\_config) | ../observability-config | n/a |
| <a name="module_rds"></a> [rds](#module\_rds) | ../rds | n/a |
| <a name="module_redis"></a> [redis](#module\_redis) | ../redis | n/a |
| <a name="module_secrets_manager"></a> [secrets\_manager](#module\_secrets\_manager) | ../secrets_manager | n/a |
| <a name="module_security_baseline"></a> [security\_baseline](#module\_security\_baseline) | ../security-baseline | n/a |
| <a name="module_security_groups"></a> [security\_groups](#module\_security\_groups) | ../security_groups | n/a |
| <a name="module_server_vpn_certificate"></a> [server\_vpn\_certificate](#module\_server\_vpn\_certificate) | ../vpn/certificates/server | n/a |
| <a name="module_service_discovery"></a> [service\_discovery](#module\_service\_discovery) | ../service-discovery | n/a |
| <a name="module_task_definition"></a> [task\_definition](#module\_task\_definition) | ../task_definition | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../vpc | n/a |
| <a name="module_vpn_association"></a> [vpn\_association](#module\_vpn\_association) | ../vpn/associations | n/a |
| <a name="module_vpn_endpoint"></a> [vpn\_endpoint](#module\_vpn\_endpoint) | ../vpn/vpn-endpoint | n/a |
| <a name="module_vpn_rules"></a> [vpn\_rules](#module\_vpn\_rules) | ../vpn/rules | n/a |
| <a name="module_waf_alb"></a> [waf\_alb](#module\_waf\_alb) | ../waf | n/a |
| <a name="module_waf_cloudfront"></a> [waf\_cloudfront](#module\_waf\_cloudfront) | ../waf | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_vpc_security_group_ingress_rule.ecs_from_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admin_cidr_blocks"></a> [admin\_cidr\_blocks](#input\_admin\_cidr\_blocks) | CIDR blocks allowed to reach Grafana (port 3000). Empty exposes nothing; use SSM port forwarding instead | `list(string)` | `[]` | no |
| <a name="input_alert_email"></a> [alert\_email](#input\_alert\_email) | Email that receives CloudWatch alarm and budget notifications; empty disables the subscription and the budget | `string` | `""` | no |
| <a name="input_api_subdomain"></a> [api\_subdomain](#input\_api\_subdomain) | Subdomain of domain\_name that points to the ALB | `string` | `"api"` | no |
| <a name="input_app_secret_name"></a> [app\_secret\_name](#input\_app\_secret\_name) | Name of the manually filled backend configuration secret in Secrets Manager | `string` | n/a | yes |
| <a name="input_create_github_oidc_provider"></a> [create\_github\_oidc\_provider](#input\_create\_github\_oidc\_provider) | Create the account-wide GitHub OIDC provider; false reads the existing one (only one may exist per account) | `bool` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Web client domain (for example example.com). Empty keeps HTTP on the ALB and the default CloudFront certificate | `string` | `""` | no |
| <a name="input_ecs_desired_count"></a> [ecs\_desired\_count](#input\_ecs\_desired\_count) | n/a | `number` | n/a | yes |
| <a name="input_ecs_log_retention_days"></a> [ecs\_log\_retention\_days](#input\_ecs\_log\_retention\_days) | n/a | `number` | n/a | yes |
| <a name="input_ecs_max_capacity"></a> [ecs\_max\_capacity](#input\_ecs\_max\_capacity) | n/a | `number` | n/a | yes |
| <a name="input_ecs_min_capacity"></a> [ecs\_min\_capacity](#input\_ecs\_min\_capacity) | n/a | `number` | n/a | yes |
| <a name="input_ecs_task_cpu"></a> [ecs\_task\_cpu](#input\_ecs\_task\_cpu) | n/a | `number` | n/a | yes |
| <a name="input_ecs_task_memory"></a> [ecs\_task\_memory](#input\_ecs\_task\_memory) | n/a | `number` | n/a | yes |
| <a name="input_enable_account_security_services"></a> [enable\_account\_security\_services](#input\_enable\_account\_security\_services) | Create the account-level CloudTrail trail, GuardDuty detector and IAM Access Analyzer; exactly one environment per account owns them | `bool` | n/a | yes |
| <a name="input_enable_client_vpn"></a> [enable\_client\_vpn](#input\_enable\_client\_vpn) | Create the Client VPN endpoint; requires the four vpn\_* PEM inputs | `bool` | n/a | yes |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Attach WAF web ACLs to the ALB and the CloudFront distribution | `bool` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, prod), the second part of every resource name | `string` | n/a | yes |
| <a name="input_hosted_zone_name"></a> [hosted\_zone\_name](#input\_hosted\_zone\_name) | Public Route 53 zone for domain\_name; defaults to domain\_name when empty | `string` | `""` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Image tag of the initial task definition revision; CD replaces the image afterwards | `string` | `"initial"` | no |
| <a name="input_monitoring_instance_type"></a> [monitoring\_instance\_type](#input\_monitoring\_instance\_type) | EC2 instance type of the monitoring host | `string` | `"t3.small"` | no |
| <a name="input_monthly_budget_usd"></a> [monthly\_budget\_usd](#input\_monthly\_budget\_usd) | Monthly cost budget in USD; 0 disables the budget | `number` | `0` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name, the first part of every resource name | `string` | n/a | yes |
| <a name="input_rds_backup_retention_period"></a> [rds\_backup\_retention\_period](#input\_rds\_backup\_retention\_period) | n/a | `number` | n/a | yes |
| <a name="input_rds_db_name"></a> [rds\_db\_name](#input\_rds\_db\_name) | n/a | `string` | n/a | yes |
| <a name="input_rds_deletion_protection"></a> [rds\_deletion\_protection](#input\_rds\_deletion\_protection) | n/a | `bool` | n/a | yes |
| <a name="input_rds_instance_class"></a> [rds\_instance\_class](#input\_rds\_instance\_class) | n/a | `string` | n/a | yes |
| <a name="input_rds_max_connections_alarm"></a> [rds\_max\_connections\_alarm](#input\_rds\_max\_connections\_alarm) | DatabaseConnections alarm threshold; about 80% of max\_connections for the RDS instance class | `number` | `320` | no |
| <a name="input_rds_multi_az"></a> [rds\_multi\_az](#input\_rds\_multi\_az) | n/a | `bool` | n/a | yes |
| <a name="input_rds_snapshot_identifier"></a> [rds\_snapshot\_identifier](#input\_rds\_snapshot\_identifier) | Encrypted DB snapshot the RDS instance is created from; null creates an empty database | `string` | `null` | no |
| <a name="input_rds_username"></a> [rds\_username](#input\_rds\_username) | n/a | `string` | n/a | yes |
| <a name="input_redis_node_type"></a> [redis\_node\_type](#input\_redis\_node\_type) | n/a | `string` | n/a | yes |
| <a name="input_redis_num_cache_clusters"></a> [redis\_num\_cache\_clusters](#input\_redis\_num\_cache\_clusters) | Redis nodes (primary plus replicas); 1 disables Multi-AZ and automatic failover | `number` | n/a | yes |
| <a name="input_redis_snapshot_retention_limit"></a> [redis\_snapshot\_retention\_limit](#input\_redis\_snapshot\_retention\_limit) | n/a | `number` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region of the regional provider | `string` | n/a | yes |
| <a name="input_secret_recovery_window_days"></a> [secret\_recovery\_window\_days](#input\_secret\_recovery\_window\_days) | Recovery window of every Secrets Manager secret; 0 deletes immediately so a recreated environment can reuse the names | `number` | n/a | yes |
| <a name="input_service_namespace"></a> [service\_namespace](#input\_service\_namespace) | Cloud Map private DNS namespace; unique per environment so two environments in one account never share a name | `string` | n/a | yes |
| <a name="input_vpc_enable_endpoints"></a> [vpc\_enable\_endpoints](#input\_vpc\_enable\_endpoints) | n/a | `bool` | n/a | yes |
| <a name="input_vpc_nat_per_az"></a> [vpc\_nat\_per\_az](#input\_vpc\_nat\_per\_az) | n/a | `bool` | n/a | yes |
| <a name="input_vpn_ca_certificate"></a> [vpn\_ca\_certificate](#input\_vpn\_ca\_certificate) | PEM body of the CA that signs the server and client certificates | `string` | `""` | no |
| <a name="input_vpn_ca_private_key"></a> [vpn\_ca\_private\_key](#input\_vpn\_ca\_private\_key) | PEM private key of the CA, imported as the client root certificate | `string` | `""` | no |
| <a name="input_vpn_server_certificate"></a> [vpn\_server\_certificate](#input\_vpn\_server\_certificate) | PEM body of the Client VPN server certificate | `string` | `""` | no |
| <a name="input_vpn_server_private_key"></a> [vpn\_server\_private\_key](#input\_vpn\_server\_private\_key) | PEM private key of the Client VPN server certificate | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_api_url"></a> [api\_url](#output\_api\_url) | Public API base URL: HTTPS on the API domain when domain\_name is set, otherwise plain HTTP on the ALB |
| <a name="output_assets_bucket_name"></a> [assets\_bucket\_name](#output\_assets\_bucket\_name) | n/a |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#output\_cloudfront\_distribution\_id) | n/a |
| <a name="output_cloudfront_url"></a> [cloudfront\_url](#output\_cloudfront\_url) | n/a |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | n/a |
| <a name="output_github_backend_role_arn"></a> [github\_backend\_role\_arn](#output\_github\_backend\_role\_arn) | n/a |
| <a name="output_github_frontend_role_arn"></a> [github\_frontend\_role\_arn](#output\_github\_frontend\_role\_arn) | n/a |
| <a name="output_web_client_bucket_name"></a> [web\_client\_bucket\_name](#output\_web\_client\_bucket\_name) | n/a |
<!-- END_TF_DOCS -->