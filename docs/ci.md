# CI for infrastructure

Workflow: `.github/workflows/terraform-ci.yml`, runs on every pull request and on pushes to `main`. It has read-only repository permissions and cancels superseded runs. All jobs are offline: none of them needs AWS credentials.

## Jobs

| Job | What it checks |
| --- | --- |
| `fmt` | `terraform fmt -check -recursive` over the whole repository |
| `validate` | `terraform init -backend=false -lockfile=readonly` and `terraform validate` in `bootstrap` and `infrastructure` (will become `environments/dev` and `environments/prod`); in `infrastructure` also `terraform test` (runs even when `validate` fails, as long as `init` succeeded) |
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
(cd infrastructure && terraform init -backend=false && terraform validate && terraform test)
docker run --rm -v "$PWD":/data -w /data ghcr.io/terraform-linters/tflint:v0.65.0 --init
docker run --rm -v "$PWD":/data -w /data ghcr.io/terraform-linters/tflint:v0.65.0 --recursive
checkov --config-file .checkov.yaml --quiet --compact
for d in $(find infrastructure/modules -name '*.tf' -exec dirname {} \; | sort -u); do
  terraform-docs -c "$PWD/.terraform-docs.yml" "$d"
done
actionlint
```

Local tool versions: Terraform 1.11.2, TFLint 0.65.0 (AWS ruleset 0.38.0), terraform-docs 0.24.0, Checkov 3.4.3. CI pins the same Terraform, TFLint and terraform-docs versions. The baseline below was recorded with them.

## Tests

`infrastructure/tests/alarms.tftest.hcl` targets the `alarms` module: the alarm count (2 ECS, 3 ALB, 3 RDS, 2 per Redis node, 1 per NAT gateway), the SNS email subscription and the budget, with negative cases (negative budget, empty `alert_email`, zero budget amount) first.

`infrastructure/tests/edge.tftest.hcl` covers the conditional edge logic with `mock_provider "aws"` and `command = plan`, so it needs no AWS credentials and creates nothing. Each run targets one module (`acm-certificate`, `load_balancer`, `dns`, `frontend`, `waf`) and asserts, for `domain_name = ""` and for a dummy domain:

- no certificate, 443 listener, validation or alias record exists without a domain, and port 80 forwards;
- with a domain there is one validated certificate, a 443 listener with `ELBSecurityPolicy-TLS13-1-2-2021-06`, a `301` redirect on port 80, `A` (API) and `A`/`AAAA` (web) alias records, and CloudFront serves the alias with `TLSv1.2_2021`;
- the regional ACL has one ALB association and the CloudFront ACL none; the rule set and the 2000/5 min rate limit;
- variable validations reject a domain without a zone or certificate and an unknown WAF scope.

Runs target modules instead of the root because the root reads the git-ignored VPN key files with `file()`, which are absent in CI. The root wiring is covered by `terraform validate`.

## Why there is no `terraform plan` in CI yet

A plan needs to read real state and refresh live resources, so the job needs AWS access. That requires an OIDC role assumed by GitHub Actions with read-only permissions on the managed resources plus read access to the S3 state bucket (and the lock file object for `use_lockfile`). Until that role exists, CI stays offline. Apply remains a manual, reviewed step.

## Baseline (to be driven to zero)

### TFLint (41 warnings)

- `terraform_required_version` (20): modules have no `required_version`.
- `terraform_required_providers` (21): modules do not declare the `aws` (and, in `secrets_manager`, `random`) provider constraint. New modules (`acm-certificate`, `alarms`, `dns`, `logs-bucket`, `waf`) and `frontend` have a `versions.tf`.
- `terraform_typed_variables`: fixed (`vpc` `cidr`).

### Checkov: 13 failed, 246 passed, 17 skipped inline

| ID | Check | Resources |
| --- | --- | --- |
| CKV_AWS_136 | Ensure that ECR repositories are encrypted using KMS | module.ecr.aws_ecr_repository.prod_forge_repo |
| CKV_AWS_163 | Ensure ECR image scanning on push is enabled | module.ecr.aws_ecr_repository.prod_forge_repo |
| CKV_AWS_23 | Ensure every security group and rule has a description | module.monitoring_sg.aws_security_group.monitoring |
| CKV_AWS_233 | Ensure Create before destroy for ACM certificates | module.client_vpn_certificate.aws_acm_certificate.vpn_client, module.server_vpn_certificate.aws_acm_certificate.vpn_server |
| CKV_AWS_290 | Ensure IAM policies does not allow write access without constraints | module.ecr.aws_iam_policy.ecr_deploy |
| CKV_AWS_355 | Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions | module.ecr.aws_iam_policy.ecr_deploy |
| CKV_AWS_382 | Ensure no security groups allow egress from 0.0.0.0:0 to port -1 | module.security_groups.aws_security_group.alb_sg, module.security_groups.aws_security_group.rds_sg, module.security_groups.aws_security_group.redis_sg, module.security_groups.aws_security_group.vpn_sg |
| CKV_AWS_51 | Ensure ECR Image Tags are immutable | module.ecr.aws_ecr_repository.prod_forge_repo |
| CKV_AWS_7 | Ensure rotation for customer created CMKs is enabled | module.secrets_manager.aws_kms_key.this |

### Inline skips

| ID | Resources | Reason |
| --- | --- | --- |
| CKV_AWS_130 | module.vpc.aws_subnet.public[*] | Public subnets host only the ALB, the NAT gateways and the monitoring EC2; ECS tasks run in private subnets |
| CKV_AWS_158 | module.vpc.aws_cloudwatch_log_group.flow_logs, module.task_definition.aws_cloudwatch_log_group.ecs, module.task_definition.aws_cloudwatch_log_group.ecs_migration | Encrypted with the CloudWatch Logs service key; no logs CMK yet |
| CKV_AWS_338 | same log groups | Operational logs, retention set by a variable (30 days in prod) to bound cost |
| CKV_AWS_394 | module.vpc.data.aws_availability_zones.available | Pinning zone names would hard-code AZs; the sorted list is sliced to `az_count` |
| CKV_AWS_150 | module.load_balancer.aws_lb.app | Deletion protection is on when `environment = "prod"`; dev stays off so it can be destroyed |
| CKV_AWS_2 | module.load_balancer.aws_lb_listener.app | Port 80 redirects to HTTPS when `domain_name` is set; plain forward is the documented no-domain fallback |
| CKV_AWS_260 | module.security_groups.aws_security_group.alb_sg | The ALB is the public entry point; port 80 only redirects when a domain is set |
| CKV_AWS_174 | module.frontend.aws_cloudfront_distribution.web_client | `TLSv1.2_2021` is enforced with a custom domain; the default `*.cloudfront.net` certificate only allows `TLSv1` |
| CKV_AWS_310 | module.frontend.aws_cloudfront_distribution.web_client | Both origins are single-region buckets; failover needs a replicated bucket that is not provisioned |
| CKV_AWS_374 | module.frontend.aws_cloudfront_distribution.web_client | The web client is public worldwide; no geo-blocking requirement |
| CKV_AWS_88 | module.monitoring_ec2.aws_instance.monitoring | Grafana is reached by IP from `admin_cidr_blocks`; SSH is gone and the host is otherwise managed through SSM |
| CKV_AWS_259 | module.frontend.aws_cloudfront_response_headers_policy.security | HSTS `preload` is a hard-to-revert commitment; off until the owner opts in |

Each following task must remove IDs from this list by fixing the resource, or by adding an inline `#checkov:skip=<ID>: <reason>` with a real reason. `.checkov.yaml` keeps `skip-check` empty. Until the list is zero the `checkov` job fails by design.
