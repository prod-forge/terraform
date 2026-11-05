# Goal

## What the project is

The infrastructure of Prod Forge: Terraform code for the AWS stack that runs the backend and the web client (`README.md`). The organization overview is at https://github.com/prod-forge; the workloads are the separate backend repository (https://github.com/prod-forge/backend) and frontend repository (https://github.com/prod-forge/frontend).

- `bootstrap/` — the S3 state bucket and its KMS key, with local state.
- `infrastructure/environments/dev`, `infrastructure/environments/prod` — the two environment roots, one `module "stack"` call each.
- `infrastructure/modules/` — the `stack` composition and the single-purpose modules: VPC, ALB, ECS Fargate, RDS PostgreSQL, ElastiCache Redis, S3 + CloudFront for the web client, ECR, GitHub OIDC deploy roles, secrets, alarms, the account security baseline, the Client VPN and the monitoring EC2 host.
- `infrastructure/observability/` — Prometheus, Grafana, Loki, Promtail and Tempo configuration uploaded to S3 for the monitoring host.
- `initial-image/` — the placeholder container image that breaks the ECR "chicken-and-egg" problem (`guide/workflow.md`).
- `.github/workflows/terraform-ci.yml` — offline CI on every pull request and on `main`.
- `guide/` — the human guide: why each decision was made.

Roots, state and environments are in [architecture/overview.md](architecture/overview.md); the modules in [architecture/modules.md](architecture/modules.md).

## What it must achieve

It answers one question: how do I run all of it on AWS with code, not clicks? (`README.md`)

- Production-ready Infrastructure as Code that follows the existing module layout and conventions (`AGENTS.md`).
- Two reproducible environments from one `stack` module; `dev` is the only step before `prod`, there is no staging (`guide/environments.md`).
- Remote, encrypted, versioned state with the S3 lock file; the bootstrap resists accidental deletion (`guide/development-setup.md`, `guide/destroy.md`).
- CI/CD of the backend and frontend repositories deploys through GitHub OIDC roles that trust only their own repository and GitHub environment, with no static credentials (`guide/workflow.md`).
- Code that does not pass `fmt`, `validate`, `terraform test`, TFLint, Checkov and the terraform-docs drift check cannot be merged (`guide/ci.md`).
- Production hardening is explained, not just applied: TLS, WAF, security headers, least-privilege IAM, CloudTrail and GuardDuty (`guide/security.md`), backups and a restore drill (`guide/backup-and-dr.md`), scaling policies (`guide/scaling.md`), alarms and the monitoring host (`guide/observability.md`), cost (`guide/cost.md`).
- Every decision is explained in `guide/`, and the docs are updated in the same change as the code (`AGENTS.md`).

Not done yet: `terraform plan` in CI, team access in Terraform, blue/green deployment (designed in `guide/blue-green.md`, not implemented). Open work is listed in the public roadmap, [roadmap.md](../roadmap.md), and tracked in [open-issues/README.md](open-issues/README.md).
