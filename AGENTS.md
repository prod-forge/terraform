# Terraform AWS DevOps Project Guidelines

## Important

- Write production-ready Infrastructure as Code
- Prefer small focused Terraform modules
- Add comments only when necessary
- Prefer explicit infrastructure configuration over magic defaults
- Preserve existing architecture and naming conventions
- Follow existing project patterns before introducing new ones
- Prefer extending existing modules over introducing new abstractions
- Reuse existing Terraform modules and locals before creating new ones
- Do not refactor unrelated infrastructure unless explicitly requested
- Split overly complex Terraform configurations into smaller modules
- Prefer minimal diffs
- Avoid reformatting unrelated files
- Prefer readable and maintainable infrastructure code
- Prefer simplicity over clever abstractions
- Avoid unnecessary module nesting
- Keep environments reproducible and deterministic
- All infrastructure changes must be idempotent
- Prefer immutable infrastructure patterns
- Avoid manual changes in AWS Console for managed resources
- Infrastructure state must always remain consistent

---

## Terraform Rules

- Use the latest stable Terraform version supported by the project
- Pin Terraform with `required_version = ">= 1.10"` and providers with a `~>` constraint; the committed `.terraform.lock.hcl` fixes the exact provider versions
- Prefer `required_providers` and `required_version`
- Use remote state for all environments
- Never store Terraform state locally for shared environments (the `bootstrap/` root is the one exception: it creates the state bucket, so its own state is local and git-ignored)
- Prefer explicit variable types
- Avoid `any` types
- Use `locals` to reduce duplication
- Prefer `for_each` over `count` when resource identity matters
- Avoid hardcoded values
- Use meaningful resource names
- Keep modules focused and cohesive
- Prefer data sources over duplicated resource definitions
- Avoid unnecessary dynamic blocks
- Use outputs only when required
- Prefer composition over deeply nested modules
- Keep plans predictable and readable
- Avoid resource recreation unless explicitly intended
- Always run `terraform fmt` and `terraform validate`
- Keep Terraform files logically separated: every root and module has `versions.tf` and `variables.tf`; `main.tf` and `outputs.tf` exist where the unit has resources or outputs. Providers, backend and `default_tags` live in the environment root's `versions.tf`; a separate `providers.tf` or `locals.tf` is not used (not applicable)

---

## AWS Rules

- Follow AWS Well-Architected Framework principles
- Prefer managed AWS services over self-hosted solutions
- Design for high availability and fault tolerance
- Prefer multi-AZ deployments for production workloads
- Use least-privilege IAM policies
- Avoid wildcard IAM permissions unless strictly required
- Enable encryption at rest and in transit
- Use AWS KMS for sensitive resources
- Prefer IAM roles over static credentials
- Never hardcode AWS credentials or secrets
- Store secrets in:
  - AWS Secrets Manager
  - AWS Systems Manager Parameter Store
- Tag all resources consistently through the provider `default_tags` of each environment root: `Project`, `Environment`, `Owner`, `CostCenter`, `ManagedBy` and `Repository`
- Prefer private subnets for internal services
- Avoid public exposure unless required
- Use Security Groups instead of overly permissive networking
- Keep VPC architecture simple and maintainable
- Prefer Auto Scaling where applicable
- Enable CloudWatch logging and monitoring by default
- Configure alarms for critical infrastructure
- Prefer S3 lifecycle policies for cost optimization
- Enable versioning for critical S3 buckets
- Block public S3 access by default
- Use the S3 backend lock file (`use_lockfile = true`) for Terraform state locking; no DynamoDB table
- Prefer ECR over external container registries for AWS workloads
- Use ALB/NLB appropriately based on workload requirements
- Enable access logging for critical services
- Prefer Graviton instances when cost-effective and supported (RDS and ElastiCache use `t4g`; Fargate tasks stay x86_64 because the images are built for `linux/amd64`)
- Use Infrastructure as Code for all AWS resources

---

## Terraform State Rules

- Use S3 backend for remote Terraform state
- Enable bucket versioning for state buckets
- Enable server-side encryption for state storage
- Use the S3 lock file (`use_lockfile = true`, Terraform 1.10+) for state locking; do not add `dynamodb_table`
- Separate state files by environment and workload (one key per root under `infrastructure/environments/<env>`)
- Never manually modify Terraform state files
- Never commit `.tfstate` files to version control
- Restrict access to Terraform state buckets

Example:

```hcl
terraform {
  backend "s3" {
    bucket       = "project-terraform-state"
    key          = "environments/dev/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}
```

---

## Module Rules

* Modules must have a single responsibility
* Keep module inputs explicit
* Avoid excessive module variables
* Provide sensible defaults only when safe
* Keep outputs minimal and intentional
* Document required inputs and outputs
* Avoid provider configuration inside reusable modules
* Prefer reusable infrastructure patterns
* Version shared modules (not applicable: all modules live in this repository and change together with the roots)
* Avoid circular module dependencies

Example structure:

```text
infrastructure/modules/
  vpc/
  ecs-service/
  rds/
  iam/
```

---

## Networking Rules

* Use a dedicated VPC per environment
* Use private/public subnet separation
* Avoid overly permissive CIDR ranges
* Minimize inbound access
* Prefer VPC endpoints for AWS service communication
* Use NAT Gateways only when necessary due to cost
* Keep routing explicit and simple
* Enable flow logs for critical environments

---

## ECS / Kubernetes Rules

* Prefer ECS Fargate unless Kubernetes is explicitly required
* Use EKS only for workloads that benefit from Kubernetes orchestration
* Keep task/container definitions explicit
* Avoid oversized container resources
* Use health checks for all services
* Prefer rolling deployments
* Store container images in ECR
* Pin container image versions
* Avoid using `latest` tags
* Configure autoscaling policies (see `guide/scaling.md`)
* Keep secrets outside container images

---

## CI/CD Rules

* All infrastructure changes must go through CI/CD (checks run in CI; apply is manual for now)
* Never apply production changes manually (target state; today applies are manual because there is no write-capable CI role, see `guide/ci.md`)
* Run `terraform fmt -check`
* Run `terraform validate`
* Run `terraform plan` in CI before apply (not yet: CI is offline, see `guide/ci.md`)
* Require manual approval for production applies (not applicable yet: CI never applies; applies are run by hand from an environment root)
* Store CI/CD secrets securely
* Prefer GitHub Actions, GitLab CI, or AWS CodePipeline
* Keep pipelines deterministic and reproducible
* Fail fast on validation errors
* Use separate AWS accounts/environments when possible

Implemented in `.github/workflows/terraform-ci.yml` (see `guide/ci.md`): `terraform fmt -check -recursive`, `terraform validate` per root, `tflint`, `checkov` and `terraform-docs` (fails on README drift). Provider lock files are committed and CI uses `-lockfile=readonly`.

Target CI steps once a read-only OIDC role exists:

```yaml
- terraform fmt -check
- terraform init
- terraform validate
- terraform plan
```

---

## Security Rules

* Apply least privilege everywhere
* Never expose secrets in logs or outputs
* Rotate credentials regularly
* Enable CloudTrail in all AWS accounts
* Enable GuardDuty for production environments
* Enable AWS Config where compliance is required (not applicable: no compliance framework applies)
* Prefer private networking
* Restrict SSH access
* Prefer SSM Session Manager over bastion hosts
* Scan Terraform code with `checkov` (used in CI); `tfsec` and `terrascan` are not used
* Review IAM changes carefully
* Enable MFA for privileged access (IAM Identity Center, see `guide/development-setup.md`)

---

## Monitoring & Observability Rules

* Centralize logs where possible
* Use CloudWatch dashboards for key services
* Configure actionable alarms
* Monitor:

    * CPU
    * Memory
    * Error rates
    * Latency
    * Cost anomalies
* Enable distributed tracing when applicable
* Keep retention policies explicit
* Avoid excessive logging costs

---

## Cost Optimization Rules

* Prefer cost-efficient managed services
* Right-size infrastructure resources
* Shut down non-production resources when unused
* Use autoscaling where appropriate
* Prefer Spot instances for fault-tolerant workloads (Fargate Spot trade-off in `guide/scaling.md`)
* Review unused resources regularly
* Use S3 lifecycle management
* Avoid unnecessary NAT Gateways
* Monitor AWS costs continuously
* Tag resources for cost allocation

---

## Testing Rules

* Infrastructure plans must be deterministic
* Validate all Terraform code before merge
* Keep tests readable and explicit
* Prefer automated infrastructure validation
* Test modules in isolation when possible
* Mock external dependencies only when necessary
* Use the `dev` environment before production rollout; there is no separate staging environment (see `guide/environments.md`)

### Validation Commands

```bash
terraform fmt -check -recursive
terraform -chdir=infrastructure/environments/prod init -backend=false
terraform -chdir=infrastructure/environments/prod validate
terraform -chdir=infrastructure/environments/prod test
```

`terraform plan` needs AWS credentials and runs by hand, not in CI.

### Tooling

```bash
tflint --recursive
docker run --rm -v "$PWD":/w -w /w --entrypoint checkov ghcr.io/bridgecrewio/checkov:3.4.3 -d infrastructure --config-file .checkov.yaml --quiet --compact
terraform-docs -c .terraform-docs.yml infrastructure/modules/<module>
```

---

## Repository Structure Rules

Actual structure:

```text
terraform/
  bootstrap/                      state bucket and KMS key (local state)
  infrastructure/
    environments/
      dev/                        root: backend, providers, variables, tfvars
      prod/                       same, plus moved.tf and tests/
    modules/
      stack/                      composition shared by both roots
      vpc/ rds/ redis/ ...        single-purpose modules
    observability/                Prometheus, Grafana and Loki templates
  docs/                           agent reference (goal, architecture, commands, restrictions, plans)
  guide/                          human guide chapters and assets
```

There is no `stage` environment and no `global/` layer.

---

## Ignore Rules

Do not analyze or modify generated/dependency files.

Ignore:

* .terraform
* .terraform.lock.hcl
* terraform.tfstate
* infrastructure/vpn-key, infrastructure/openvpn, infrastructure/ssh (git-ignored key material)
* terraform.tfstate.backup
* crash.log
* *.tfvars
* override.tf
* override.tf.json
* *.auto.tfvars

Never commit secrets or state files.

---

## Cost Saving Rules

* Run only affected Terraform plans when possible
* Avoid full environment applies for isolated changes
* Read only relevant modules and environments
* Avoid scanning the entire repository unless necessary
* Prefer targeted validation for changed infrastructure
* Use cached providers in CI/CD when possible
* Minimize unnecessary AWS resource recreation

---

## Documentation

Agent reference docs live in `docs/`; the human guide lives in `guide/`:

- `docs/goal.md` — what the project is and what it must achieve
- `docs/architecture/` — roots, state backend, dev/prod differences, outputs consumed by CD (`overview.md`), modules and what they provision, conditional HTTPS (`modules.md`), conventions and how to add a module, variable, environment value or output (`patterns.md`)
- `docs/commands.md` — tool versions, local checks, plan by hand, CI jobs, git hooks, commands agents must never run
- `docs/restrictions/` — constraints of this project, with the reason and where each is enforced
- `docs/plans/` — what is being implemented now
- `docs/ideas/` — raw high-level ideas
- `docs/roadmap/` — ideas scheduled into versions; the public list of open work is `roadmap.md`
- `docs/open-issues/` — deferred known problems
- `docs/postmortem/` — attempts that did not work, and why
- `docs/hacks/` — non-obvious decisions and shortcuts

When making changes that affect any of the above, update the relevant doc in the same task. Do not defer doc updates to a follow-up. A module, root, backend setting, environment value or output that is added, removed or changed updates `docs/architecture/`; a change to tooling, CI or the hooks updates `docs/commands.md`.

The human guide in `guide/` is updated when the behaviour it describes changes.

## Planning

- Before writing a new plan, read `docs/goal.md`, `docs/architecture/` and `docs/restrictions/`
- Plans follow `docs/plans/README.md`: a global plan (`NNN-<name>/` with `readme.md` and `00-design.md`), plans inside it, one file per step; every level carries status, version, date and modules
- The design ends with open questions, the user's decisions and your own calls to check; implement only approved plans
- A plan is done when its conclusions are written and the user has looked at its result
- Shortcuts go to `docs/hacks/`, deferred problems to `docs/open-issues/`, failed attempts to `docs/postmortem/`
