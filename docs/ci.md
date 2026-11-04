# CI for infrastructure

Workflow: `.github/workflows/terraform-ci.yml`, runs on every pull request and on pushes to `main`. It has read-only repository permissions and cancels superseded runs. All jobs are offline: none of them needs AWS credentials.

## Jobs

| Job | What it checks |
| --- | --- |
| `fmt` | `terraform fmt -check -recursive` over the whole repository |
| `validate` | `terraform init -backend=false -lockfile=readonly` and `terraform validate` in `bootstrap` and `infrastructure` (will become `environments/dev` and `environments/prod`) |
| `tflint` | `tflint --init && tflint --recursive` with `.tflint.hcl` (AWS ruleset, required version, naming convention, unused declarations) |
| `checkov` | Static security scan of `infrastructure` with `.checkov.yaml`, `soft_fail: false` |
| `terraform-docs` | Regenerates each module `README.md` between `BEGIN_TF_DOCS`/`END_TF_DOCS` and fails on any diff |

## Reproducibility

`.terraform.lock.hcl` is committed for `bootstrap` and `infrastructure` (hashes for `linux_amd64` and `darwin_arm64`), `required_version` is `>= 1.10`, and CI runs `init -lockfile=readonly`, so provider upgrades are always an explicit commit:

```bash
terraform init -upgrade -backend=false
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
```

## Running locally

```bash
terraform fmt -check -recursive
(cd bootstrap && terraform init -backend=false && terraform validate)
(cd infrastructure && terraform init -backend=false && terraform validate)
docker run --rm -v "$PWD":/data -w /data ghcr.io/terraform-linters/tflint:latest --init
docker run --rm -v "$PWD":/data -w /data ghcr.io/terraform-linters/tflint:latest --recursive
checkov --config-file .checkov.yaml --quiet --compact
for d in $(find infrastructure/modules -name '*.tf' -exec dirname {} \; | sort -u); do
  terraform-docs -c "$PWD/.terraform-docs.yml" "$d"
done
actionlint
```

The baseline below was recorded with TFLint 0.65.0 (AWS ruleset 0.38.0) and Checkov 3.4.3.

## Why there is no `terraform plan` in CI yet

A plan needs to read real state and refresh live resources, so the job needs AWS access. That requires an OIDC role assumed by GitHub Actions with read-only permissions on the managed resources plus read access to the S3 state bucket (and the lock file object for `use_lockfile`). Until that role exists, CI stays offline. Apply remains a manual, reviewed step.

## Baseline (to be driven to zero)

### TFLint (45 warnings)

- `terraform_required_version` (22): modules have no `required_version`.
- `terraform_required_providers` (22): modules do not declare the `aws` provider constraint.
- `terraform_typed_variables`: fixed (`vpc` `cidr`).

### Checkov: 59 failed, 127 passed

| ID | Check | Resources |
| --- | --- | --- |
| CKV_AWS_118 | Ensure that enhanced monitoring is enabled for Amazon RDS instances | module.rds.aws_db_instance.postgres |
| CKV_AWS_126 | Ensure that detailed monitoring is enabled for EC2 instances | module.monitoring_ec2.aws_instance.monitoring |
| CKV_AWS_129 | Ensure that respective logs of Amazon Relational Database Service (Amazon RDS) are enabled | module.rds.aws_db_instance.postgres |
| CKV_AWS_130 | Ensure VPC subnets do not assign public IP by default | module.vpc.aws_subnet.public[0], module.vpc.aws_subnet.public[1] |
| CKV_AWS_131 | Ensure that ALB drops HTTP headers | module.load_balancer.aws_lb.app |
| CKV_AWS_134 | Ensure that Amazon ElastiCache Redis clusters have automatic backup turned on | module.redis.aws_elasticache_cluster.redis |
| CKV_AWS_135 | Ensure that EC2 is EBS optimized | module.monitoring_ec2.aws_instance.monitoring |
| CKV_AWS_136 | Ensure that ECR repositories are encrypted using KMS | module.ecr.aws_ecr_repository.prod_forge_repo |
| CKV_AWS_150 | Ensure that Load Balancer has deletion protection enabled | module.load_balancer.aws_lb.app |
| CKV_AWS_157 | Ensure that RDS instances have Multi-AZ enabled | module.rds.aws_db_instance.postgres |
| CKV_AWS_158 | Ensure that CloudWatch Log Group is encrypted by KMS | module.task_definition.aws_cloudwatch_log_group.ecs, module.task_definition.aws_cloudwatch_log_group.ecs_migration |
| CKV_AWS_16 | Ensure all data stored in the RDS is securely encrypted at rest | module.rds.aws_db_instance.postgres |
| CKV_AWS_161 | Ensure RDS database has IAM authentication enabled | module.rds.aws_db_instance.postgres |
| CKV_AWS_163 | Ensure ECR image scanning on push is enabled | module.ecr.aws_ecr_repository.prod_forge_repo |
| CKV_AWS_174 | Verify CloudFront Distribution Viewer Certificate is using TLS v1.2 or higher | module.frontend.aws_cloudfront_distribution.web_client |
| CKV_AWS_2 | Ensure ALB protocol is HTTPS | module.load_balancer.aws_lb_listener.app |
| CKV_AWS_226 | Ensure DB instance gets all minor upgrades automatically | module.rds.aws_db_instance.postgres |
| CKV_AWS_23 | Ensure every security group and rule has a description | module.monitoring_sg.aws_security_group.monitoring, module.security_groups.aws_security_group.alb_sg, module.security_groups.aws_security_group.ecs_sg, module.security_groups.aws_security_group.rds_sg, module.security_groups.aws_security_group.redis_sg, module.security_groups.aws_security_group.vpn_sg |
| CKV_AWS_233 | Ensure Create before destroy for ACM certificates | module.client_vpn_certificate.aws_acm_certificate.vpn_client, module.server_vpn_certificate.aws_acm_certificate.vpn_server |
| CKV_AWS_24 | Ensure no security groups allow ingress from 0.0.0.0:0 to port 22 | module.monitoring_sg.aws_security_group.monitoring, module.security_groups.aws_security_group.vpn_sg |
| CKV_AWS_25 | Ensure no security groups allow ingress from 0.0.0.0:0 to port 3389 | module.security_groups.aws_security_group.vpn_sg |
| CKV_AWS_259 | Ensure CloudFront response header policy enforces Strict Transport Security | module.frontend.aws_cloudfront_response_headers_policy.security |
| CKV_AWS_260 | Ensure no security groups allow ingress from 0.0.0.0:0 to port 80 | module.security_groups.aws_security_group.alb_sg, module.security_groups.aws_security_group.vpn_sg |
| CKV_AWS_277 | Ensure no security groups allow ingress from 0.0.0.0:0 to port -1 | module.security_groups.aws_security_group.vpn_sg |
| CKV_AWS_290 | Ensure IAM policies does not allow write access without constraints | module.ecr.aws_iam_policy.ecr_deploy, module.ecs_service.aws_iam_policy.ecs_deploy |
| CKV_AWS_293 | Ensure that AWS database instances have deletion protection enabled | module.rds.aws_db_instance.postgres |
| CKV_AWS_310 | Ensure CloudFront distributions should have origin failover configured | module.frontend.aws_cloudfront_distribution.web_client |
| CKV_AWS_333 | Ensure ECS services do not have public IP addresses assigned to them automatically | module.ecs_service.aws_ecs_service.app |
| CKV_AWS_338 | Ensure CloudWatch log groups retains logs for at least 1 year | module.task_definition.aws_cloudwatch_log_group.ecs, module.task_definition.aws_cloudwatch_log_group.ecs_migration |
| CKV_AWS_353 | Ensure that RDS instances have performance insights enabled | module.rds.aws_db_instance.postgres |
| CKV_AWS_355 | Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions | module.ecr.aws_iam_policy.ecr_deploy, module.ecs_service.aws_iam_policy.ecs_deploy |
| CKV_AWS_374 | Ensure AWS CloudFront web distribution has geo restriction enabled | module.frontend.aws_cloudfront_distribution.web_client |
| CKV_AWS_382 | Ensure no security groups allow egress from 0.0.0.0:0 to port -1 | module.security_groups.aws_security_group.alb_sg, module.security_groups.aws_security_group.ecs_sg, module.security_groups.aws_security_group.rds_sg, module.security_groups.aws_security_group.redis_sg, module.security_groups.aws_security_group.vpn_sg |
| CKV_AWS_51 | Ensure ECR Image Tags are immutable | module.ecr.aws_ecr_repository.prod_forge_repo |
| CKV_AWS_65 | Ensure container insights are enabled on ECS cluster | module.ecs_cluster.aws_ecs_cluster.app |
| CKV_AWS_68 | CloudFront Distribution should have WAF enabled | module.frontend.aws_cloudfront_distribution.web_client |
| CKV_AWS_7 | Ensure rotation for customer created CMKs is enabled | module.secrets_manager.aws_kms_key.this |
| CKV_AWS_79 | Ensure Instance Metadata Service Version 1 is not enabled | module.monitoring_ec2.aws_instance.monitoring |
| CKV_AWS_8 | Ensure all data stored in the Launch configuration or instance Elastic Blocks Store is securely encrypted | module.monitoring_ec2.aws_instance.monitoring |
| CKV_AWS_86 | Ensure CloudFront distribution has Access Logging enabled | module.frontend.aws_cloudfront_distribution.web_client |
| CKV_AWS_88 | EC2 instance should not have public IP. | module.monitoring_ec2.aws_instance.monitoring |
| CKV_AWS_91 | Ensure the ELBv2 (Application/Network) has access logging enabled | module.load_balancer.aws_lb.app |

Each following task must remove IDs from this list by fixing the resource, or by adding an inline `#checkov:skip=<ID>: <reason>` with a real reason. `.checkov.yaml` keeps `skip-check` empty. Until the list is zero the `checkov` job fails by design.
