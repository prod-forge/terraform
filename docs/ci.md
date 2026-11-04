# CI for infrastructure

Workflow: `.github/workflows/terraform-ci.yml`, runs on every pull request and on pushes to `main`. It has read-only repository permissions and cancels superseded runs. All jobs are offline: none of them needs AWS credentials.

## Jobs

| Job | What it checks |
| --- | --- |
| `fmt` | `terraform fmt -check -recursive` over the whole repository |
| `validate` | `terraform init -backend=false -lockfile=readonly` and `terraform validate` in `bootstrap`, `infrastructure/environments/dev` and `infrastructure/environments/prod`; in `infrastructure/environments/prod` also `terraform test` (runs even when `validate` fails, as long as `init` succeeded) |
| `tflint` | `tflint --init && tflint --recursive` with `.tflint.hcl` (AWS ruleset, required version, naming convention, unused declarations) |
| `checkov` | Static security scan of `infrastructure` with `.checkov.yaml`, `soft_fail: false` |
| `terraform-docs` | Regenerates each module `README.md` between `BEGIN_TF_DOCS`/`END_TF_DOCS` and fails on any diff |

## Reproducibility

`.terraform.lock.hcl` is committed for `bootstrap`, `infrastructure/environments/dev` and `infrastructure/environments/prod` (hashes for `linux_amd64` and `darwin_arm64`), `required_version` is `>= 1.10`, and CI runs `init -lockfile=readonly`, so provider upgrades are always an explicit commit:

```bash
terraform init -upgrade -backend=false
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
```

## Running locally

```bash
terraform fmt -check -recursive
(cd bootstrap && terraform init -backend=false && terraform validate)
(cd infrastructure/environments/dev && terraform init -backend=false && terraform validate)
(cd infrastructure/environments/prod && terraform init -backend=false && terraform validate && terraform test)
docker run --rm -v "$PWD":/data -w /data ghcr.io/terraform-linters/tflint:v0.65.0 --init
docker run --rm -v "$PWD":/data -w /data ghcr.io/terraform-linters/tflint:v0.65.0 --recursive
checkov --config-file .checkov.yaml --quiet --compact
for d in $(find infrastructure/modules -name '*.tf' -exec dirname {} \; | sort -u); do
  terraform-docs -c "$PWD/.terraform-docs.yml" "$d"
done
actionlint
```

`terraform test` uses `override_during` in `override_data`/`override_resource` blocks, which needs Terraform 1.11 or newer, while `required_version` stays `>= 1.10` for plain `plan`/`apply`. CI pins 1.11.2, so run the tests with 1.11 or newer locally.

Local tool versions: Terraform 1.11.2, TFLint 0.65.0 (AWS ruleset 0.38.0), terraform-docs 0.24.0, Checkov 3.4.3. CI pins the same Terraform, TFLint and terraform-docs versions. The baseline below was recorded with them.

## Tests

All test files live in `infrastructure/environments/prod/tests/` and run with `terraform test` from `infrastructure/environments/prod`. Every run uses `mock_provider "aws"` and `command = plan`, so it needs no AWS credentials and creates nothing. Negative cases come first in each file.

`stack.tftest.hcl` plans the whole prod root (all modules through `module.stack`) with `vpn_key_dir` pointing at a missing directory:

- `enable_client_vpn = true` without the key files is rejected by the `enable_client_vpn` validation;
- the prod root plans end to end without the git-ignored VPN files, and names follow `<project>-<environment>-<name>`;
- the dev switches (`environment = "dev"`, no WAF, no VPN, OIDC provider read instead of created, one Redis node, the `<project>-dev.local` namespace, no budget) plan end to end.

`alarms.tftest.hcl` targets the `alarms` module: the alarm count (2 ECS, 3 ALB, 3 RDS, 2 per Redis node, 1 per NAT gateway), the SNS email subscription and the budget, with negative cases (negative budget, empty `alert_email`, zero budget amount) first.

`edge.tftest.hcl` covers the conditional edge logic. Each run targets one module (`acm-certificate`, `load_balancer`, `dns`, `frontend`, `waf`) and asserts, for `domain_name = ""` and for a dummy domain:

- no certificate, 443 listener, validation or alias record exists without a domain, and port 80 forwards;
- with a domain there is one validated certificate, a 443 listener with `ELBSecurityPolicy-TLS13-1-2-2021-06`, a `301` redirect on port 80, `A` (API) and `A`/`AAAA` (web) alias records, and CloudFront serves the alias with `TLSv1.2_2021`;
- the regional ACL has one ALB association and the CloudFront ACL none; the rule set and the 2000/5 min rate limit;
- variable validations reject a domain without a zone or certificate and an unknown WAF scope.

`security-baseline.tftest.hcl` checks the multi-region, validated, KMS-encrypted trail with its bucket lifecycle, the GuardDuty detector and the Access Analyzer, that every switch off creates nothing, and that a retention shorter than the archive age is rejected.

`github-oidc.tftest.hcl` checks that each GitHub role trusts only its own repository and environment; `observability.tftest.hcl` checks the observability config upload and the Cloud Map namespace.

The environment roots read the VPN key files with `fileexists()`, so `terraform validate` and `terraform test` work in a fresh clone without them; the root wiring is covered by `validate` in CI for both environments and by `stack.tftest.hcl`. The module-level tests keep targeting modules directly because `module.stack` declares `configuration_aliases` for the us-east-1 provider and cannot be the `module` of a run block.

## Why there is no `terraform plan` in CI yet

A plan needs to read real state and refresh live resources, so the job needs AWS access. That requires an OIDC role assumed by GitHub Actions with read-only permissions on the managed resources plus read access to the S3 state bucket (and the lock file object for `use_lockfile`). Until that role exists, CI stays offline. Apply remains a manual, reviewed step.

## Baseline

Both scanners are at zero: `tflint --recursive` reports no issues (every module has a `versions.tf` with `required_version >= 1.10` and its provider constraints), and `checkov -d infrastructure` reports no failed checks. Checkov evaluates the modules through both environment roots, so a resource whose setting differs per environment is checked with the dev values too; those cases have inline skips that name the variable.

### Inline skips

| ID | Resources | Reason |
| --- | --- | --- |
| CKV_AWS_130 | module.vpc.aws_subnet.public[*] | Public subnets host only the ALB, the NAT gateways and the monitoring EC2; ECS tasks run in private subnets |
| CKV_AWS_158 | module.vpc.aws_cloudwatch_log_group.flow_logs, module.task_definition.aws_cloudwatch_log_group.ecs, module.task_definition.aws_cloudwatch_log_group.ecs_migration | Encrypted with the CloudWatch Logs service key; no logs CMK yet |
| CKV_AWS_338 | same log groups | Operational logs, retention set by a variable (30 days in prod) to bound cost |
| CKV_AWS_394 | module.vpc.data.aws_availability_zones.available | Pinning zone names would hard-code AZs; the sorted list is sliced to `az_count` |
| CKV_AWS_150 | module.load_balancer.aws_lb.app | Deletion protection is on when `environment = "prod"`; dev stays off so it can be destroyed |
| CKV_AWS_157 | module.rds.aws_db_instance.postgres | Multi-AZ comes from `rds_multi_az`: true in prod, false in dev to halve the cost |
| CKV_AWS_293 | module.rds.aws_db_instance.postgres | Deletion protection comes from `rds_deletion_protection`: true in prod, false in dev so it can be destroyed |
| CKV_AWS_2 | module.load_balancer.aws_lb_listener.app | Port 80 redirects to HTTPS when `domain_name` is set; plain forward is the documented no-domain fallback |
| CKV_AWS_260 | module.security_groups.aws_security_group.alb_sg | The ALB is the public entry point; port 80 only redirects when a domain is set |
| CKV_AWS_174 | module.frontend.aws_cloudfront_distribution.web_client | `TLSv1.2_2021` is enforced with a custom domain; the default `*.cloudfront.net` certificate only allows `TLSv1` |
| CKV_AWS_310 | module.frontend.aws_cloudfront_distribution.web_client | Both origins are single-region buckets; failover needs a replicated bucket that is not provisioned |
| CKV_AWS_374 | module.frontend.aws_cloudfront_distribution.web_client | The web client is public worldwide; no geo-blocking requirement |
| CKV_AWS_88 | module.monitoring_ec2.aws_instance.monitoring | Grafana is reached by IP from `admin_cidr_blocks`; SSH is gone and the host is otherwise managed through SSM |
| CKV_AWS_259 | module.frontend.aws_cloudfront_response_headers_policy.security | HSTS `preload` is a hard-to-revert commitment; off until the owner opts in |

The CloudTrail checks CKV_AWS_35 (KMS), CKV_AWS_36 (log file validation), CKV_AWS_67 (all regions) and CKV_AWS_252 (SNS topic) pass on `module.security_baseline`. CKV2_AWS_3 (GuardDuty) does not exist in Checkov 3.4.3; its GuardDuty check is CKV_AWS_238 (detector enabled), which passes.

`.checkov.yaml` keeps `skip-check` empty. A new finding must be fixed, or skipped inline with `#checkov:skip=<ID>: <reason>` and a real reason, and added to this table.
