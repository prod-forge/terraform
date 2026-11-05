# Architecture

## Overview

Terraform for the Prod Forge AWS stack: the NestJS backend on ECS Fargate behind an ALB, PostgreSQL on RDS, Redis on
ElastiCache, the web client on S3 + CloudFront, and a self-hosted Prometheus/Grafana/Loki host on EC2.

**Stack:** Terraform `>= 1.10` (CI pins 1.11.2) · AWS provider `~> 6.35` · random provider `~> 3.7` · region
`eu-central-1`

The human guide (`guide/`) explains the why; these files map where things are. The modules and conditional HTTPS are in [modules.md](modules.md); how to add a module, variable, environment value or output is in [patterns.md](patterns.md).

---

## Roots

There are three Terraform roots. Each one is initialised and applied on its own.

| Root                               | State                                                                      | Purpose                                         |
| ---------------------------------- | -------------------------------------------------------------------------- | ----------------------------------------------- |
| `bootstrap/`                       | local, git-ignored                                                         | state bucket and its KMS key                    |
| `infrastructure/environments/prod` | S3 `prod-forge-todolist-terraform-state-prod`, key `infrastructure/terraform.tfstate` | prod: one `module "stack"` call     |
| `infrastructure/environments/dev`  | same bucket, key `environments/dev/terraform.tfstate`                      | dev: one `module "stack"` call                  |

Both environment roots have the same `main.tf`, `variables.tf` and `outputs.tf`; they differ only in the backend key
(`versions.tf`) and in `terraform.tfvars`. `prod` also has `moved.tf` and `tests/`.

```text
bootstrap/                      main.tf, variables.tf, versions.tf, prod.auto.tfvars
infrastructure/
  environments/
    dev/                        versions.tf (backend, providers), main.tf (module "stack"), variables.tf, outputs.tf, terraform.tfvars
    prod/                       same, plus moved.tf and tests/*.tftest.hcl
  modules/
    stack/                      composition of every other module, shared by both roots
    <module>/                   single-purpose modules (see modules.md)
  observability/                Prometheus, Grafana, Loki, Promtail, Tempo config and dashboards, uploaded to S3
  certificate/openssl.cnf       OpenSSL config for the Client VPN certificates
initial-image/                  placeholder container image (Dockerfile, server.js)
guide/                          human guide
docs/                           agent reference (goal, architecture, commands, restrictions, plans)
```

### `bootstrap/`

Creates, with local state (`bootstrap/versions.tf` has no backend block):

- `aws_kms_key.terraform_state` with key rotation
- `aws_s3_bucket.terraform_state` named `${project}-terraform-state-${environment}` with `prevent_destroy`, versioning,
  public access block, SSE-KMS, a 90-day noncurrent version expiry and a bucket policy that denies non-TLS access

Values come from `bootstrap/prod.auto.tfvars`.

### Environment roots

`infrastructure/environments/<env>/versions.tf` holds the S3 backend, the default `aws` provider, the `aws.us_east_1`
alias (CloudFront certificates and CLOUDFRONT-scope WAF) and the `default_tags` (`Project`, `Environment`, `Owner`,
`CostCenter`, `ManagedBy`, `Repository`).

`main.tf` reads the Client VPN key files from `var.vpn_key_dir` with `fileexists` (missing files resolve to `""`) and
passes every variable through to `module "stack"`.

`prod/moved.tf` holds 31 `moved` blocks from the former single `infrastructure/` root to `module.stack.*`; see
`guide/migration-to-environments.md`.

`prod/tests/*.tftest.hcl` are offline `terraform test` runs with `mock_provider` (alarms, edge, github-oidc,
observability, security-baseline, stack, task-definition).

---

## State backend

```hcl
backend "s3" {
  bucket       = "prod-forge-todolist-terraform-state-prod"
  key          = "infrastructure/terraform.tfstate" # dev: environments/dev/terraform.tfstate
  region       = "eu-central-1"
  use_lockfile = true
  encrypt      = true
}
```

Locking is the S3 lock file (`use_lockfile = true`). There is no DynamoDB table. The prod key is the key of the former
single root, so the live state was migrated in place.

---

## How dev and prod differ

Apart from the backend state key in `versions.tf`, the differences are values in
`infrastructure/environments/<env>/terraform.tfvars`:

| Setting                                | prod                                    | dev                                   |
| -------------------------------------- | --------------------------------------- | ------------------------------------- |
| RDS                                    | `db.t4g.medium`, Multi-AZ, 7-day backups, deletion protection | `db.t4g.micro`, single AZ, 1-day backups, no deletion protection |
| Redis                                  | `cache.t4g.small` x 2, 7 snapshots      | `cache.t4g.micro` x 1, 1 snapshot     |
| NAT / VPC endpoints                    | NAT per AZ, endpoints on                | one NAT, endpoints off                |
| ECS                                    | 2 tasks (2..10), 512 CPU / 1024 MiB, 30-day logs | 1 task (1..2), 256 CPU / 512 MiB, 7-day logs |
| WAF                                    | on                                      | off                                   |
| Client VPN                             | on                                      | off                                   |
| Secret recovery window                 | 30 days                                 | 0 (immediate delete)                  |
| GitHub OIDC provider, account security services | created by prod                | read / skipped (shared account)       |
| Alert email, monthly budget            | set, `800` USD                          | empty, `0` (none)                     |
| Backend log level, DB pool size        | `info`, 10 per task                     | `trace`, 5 per task                   |
| RDS connections alarm threshold        | 320                                     | 90                                    |
| Cloud Map namespace                    | `prod-forge-todolist.local`             | `prod-forge-todolist-dev.local`       |

The ALB deletion protection follows `environment == "prod"` in `modules/load_balancer/main.tf`.

---

## Outputs consumed by CD

Both environment roots re-export the stack outputs (`infrastructure/environments/<env>/outputs.tf`). They are copied
by hand into GitHub variables of the backend and frontend repos (`guide/workflow.md#deploy-workflow-variables`):

| Consumer | Outputs                                                                                                                                                                                                                    |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| backend  | `github_backend_role_arn`, `ecr_repository_name`, `ecs_cluster_name`, `ecs_service_name`, `ecs_task_definition_family`, `ecs_migration_task_definition_family`, `ecs_migration_log_group_name`, `private_subnet_ids`, `ecs_security_group_id` |
| frontend | `github_frontend_role_arn`, `web_client_bucket_name`, `assets_bucket_name`, `cloudfront_distribution_id`, `cloudfront_url`, `api_url`                                                                                        |

Also exported, not in the CD variable mapping: `ecr_repository_url`, `ecs_log_group_name`.

The migration task definition family (`${project}-${environment}-migration-task`) is registered by backend CD, not by
Terraform; the deploy role may run only that family.
