# Architecture

## Overview

Terraform for the Prod Forge AWS stack: the NestJS backend on ECS Fargate behind an ALB, PostgreSQL on RDS, Redis on
ElastiCache, the web client on S3 + CloudFront, and a self-hosted Prometheus/Grafana/Loki host on EC2.

**Stack:** Terraform `>= 1.10` (CI pins 1.11.2) · AWS provider `~> 6.35` · random provider `~> 3.7` · region
`eu-central-1`

The human guide (`guide/`) explains the why; this file maps where things are.

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
    <module>/                   single-purpose modules (see below)
  observability/                Prometheus, Grafana, Loki, Promtail, Tempo config and dashboards, uploaded to S3
  certificate/openssl.cnf       OpenSSL config for the Client VPN certificates
initial-image/                  placeholder container image (Dockerfile, server.js)
guide/                          human guide
docs/                           agent reference (this folder)
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

## Modules

`infrastructure/modules/stack/main.tf` calls every module below. Resource names are prefixed with
`${project}-${environment}`.

| Module                         | Provisions                                                                                                                                             |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `vpc`                          | VPC, public and private subnets over `az_count` (default 2) AZs, IGW, NAT gateways (one, or one per AZ with `nat_per_az`), DB subnet group, flow logs, S3 gateway endpoint; interface endpoints (`ecr.api`, `ecr.dkr`, `secretsmanager`, `logs`, `ssmmessages`) only when `enable_vpc_endpoints` |
| `security_groups`              | security groups for the ALB, ECS, RDS, Redis and the VPN, with the ECS ingress/egress rules                                                            |
| `load_balancer`                | ALB with access logs, target group, HTTP listener, HTTPS listener (only with a domain), a listener rule that answers 404 on `/metrics*` and `/api/metrics*`; deletion protection when `environment == "prod"` |
| `logs-bucket`                  | S3 bucket for ALB and CloudFront access logs                                                                                                           |
| `waf`                          | WAFv2 web ACL; associated with the ALB when `scope = "REGIONAL"`. Called twice (ALB and CloudFront, the latter in `us-east-1`) when `enable_waf`        |
| `acm-certificate`              | ACM certificate with Route 53 DNS validation, only when `domain_name` is set. Called for the API (regional) and for CloudFront (`us-east-1`)            |
| `dns`                          | looks up the hosted zone and creates the API alias record and the web `A`/`AAAA` alias records, only when `domain_name` is set                          |
| `ecr`                          | ECR repository with a lifecycle policy, and the push policy for the backend deploy role                                                               |
| `github-oidc`                  | GitHub OIDC provider (created when `create_github_oidc_provider`, otherwise read as a data source) and the backend and frontend deploy roles           |
| `secrets_manager`              | KMS key, the app config secret, and generated Redis auth, JWT and Grafana admin secrets                                                                |
| `iam`                          | ECS task execution role and task role with secret read access                                                                                          |
| `ecs-cluster`                  | ECS cluster and its capacity providers                                                                                                                 |
| `task_definition`              | backend task definition and the CloudWatch log groups of the app and migration tasks                                                                    |
| `ecs-service`                  | ECS Fargate service, autoscaling target with CPU and request-count policies, deploy and `iam:PassRole` policies for the backend deploy role            |
| `service-discovery`            | Cloud Map private DNS namespace and the backend service                                                                                                |
| `rds`                          | PostgreSQL `aws_db_instance`, parameter group, enhanced monitoring role                                                                                 |
| `redis`                        | ElastiCache subnet group and replication group                                                                                                         |
| `frontend`                     | web client and assets S3 buckets, CloudFront distribution with OAC and a security headers policy, deploy policy for the frontend role                  |
| `observability-config`         | S3 bucket with the files of `infrastructure/observability/` (`*.tftpl` rendered with the Cloud Map namespace)                                         |
| `monitoring/iam`               | instance role and profile of the monitoring host (SSM, Grafana secret, config bucket)                                                                  |
| `monitoring/security_group`    | security group of the monitoring host                                                                                                                  |
| `monitoring/ec2`               | monitoring EC2 instance (Ubuntu 24.04, `templates/bootstrap.sh.tpl` user data, no key pair)                                                            |
| `alarms`                       | SNS topic (KMS-encrypted) with optional email subscription, CloudWatch alarms for ECS, ALB, RDS, Redis and NAT, optional monthly budget                 |
| `security-baseline`            | CloudTrail (bucket, KMS key, SNS topic), GuardDuty detector, IAM Access Analyzer, each behind its own flag                                             |
| `vpn/certificates/{server,client}` | imported ACM certificates for the Client VPN                                                                                                      |
| `vpn/vpn-endpoint`             | Client VPN endpoint                                                                                                                                    |
| `vpn/associations`             | Client VPN association with the first private subnet                                                                                                   |
| `vpn/rules`                    | Client VPN authorization rule for the VPC CIDR                                                                                                         |

All `vpn/*` modules are created only when `enable_client_vpn`. The stack itself adds one resource: the ECS ingress
rule on port 3000 from the monitoring security group (Prometheus scrape).

Modules declare only `required_providers`; providers are configured in the environment roots. `stack` declares
`configuration_aliases = [aws.us_east_1]`.

---

## How dev and prod differ

All differences are values in `infrastructure/environments/<env>/terraform.tfvars`:

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
| Cloud Map namespace                    | `prod-forge-todolist.local`             | `prod-forge-todolist-dev.local`       |

The ALB deletion protection follows `environment == "prod"` in `modules/load_balancer/main.tf`.

---

## Conditional HTTPS

Everything domain-related keys off `var.domain_name` (empty in both `terraform.tfvars` today):

- `acm-certificate` and `dns`: `enabled = var.domain_name != ""`, resources use `count`
- `load_balancer`: `https_enabled = var.domain_name != ""`; with a domain the HTTP listener redirects to the HTTPS
  listener, without one it forwards to the target group (plain HTTP)
- `frontend`: with a domain CloudFront gets the alias and the `us-east-1` ACM certificate, otherwise the default
  CloudFront certificate
- `stack`: `api_url` is `https://<api_subdomain>.<domain_name>` with a domain, otherwise `http://<alb dns name>`;
  CORS origins are the custom domain (when set) and the CloudFront domain

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
