# AWS safety

## Agents never change AWS

- **Rule:** never run `terraform apply`, `terraform destroy`, `terraform plan`, `terraform init` with a backend, or any AWS CLI command that changes resources. Only the owner does, from an environment root.
- **Reason:** there is one shared AWS account with real resources and real cost; a plan needs credentials and reads live state; an apply can replace RDS, the monitoring host or the security groups. There is no write-capable CI role yet (`guide/ci.md`, "Why there is no `terraform plan` in CI yet").
- **Where:** [commands.md](../commands.md#what-agents-must-never-run), `AGENTS.md` ("CI/CD Rules"). CI has no AWS credentials (`.github/workflows/terraform-ci.yml`, `permissions: contents: read`). Nothing in the tooling blocks the commands locally.

## Secrets stay out of the code and the outputs

- **Rule:** no credentials, secret values or PEM bodies in `*.tf`, `*.tfvars` or outputs. Secrets live in Secrets Manager; outputs expose ARNs, not values.
- **Reason:** state, plans and CI logs are readable by more people than the secrets; the backend reads its secrets at runtime from Secrets Manager (`guide/workflow.md`, "AWS Secrets Manager").
- **Where:** `infrastructure/modules/secrets_manager/` (generated Redis auth, JWT and Grafana secrets; outputs are ARNs); `sensitive = true` on the `vpn_*` variables of `infrastructure/modules/stack/variables.tf`; Checkov in CI.

## Key material is git-ignored

- **Rule:** never read, print or commit the files in `infrastructure/vpn-key`, `infrastructure/openvpn`, `infrastructure/ssh`, or any `.ovpn` file.
- **Reason:** they hold the Client VPN CA and server private keys (`guide/debugging.md`, "Generate Certificates").
- **Where:** `.gitignore` (`vpn-key`, `openvpn`, `ssh`). The roots read the keys with `fileexists` and fail the plan when `enable_client_vpn` is on without them (`validation` on `enable_client_vpn` in `infrastructure/environments/<env>/variables.tf`).

## No unintended replacements

- **Rule:** a change must not recreate a live resource unless the replacement is the intent. A renamed or moved address gets a `moved` block.
- **Reason:** a replaced RDS instance, ECR repository or monitoring host loses data or causes downtime; the environments migration listed every accepted replacement in advance (`guide/migration-to-environments.md`, "What Is Replaced").
- **Where:** `infrastructure/environments/prod/moved.tf`, the `lifecycle` blocks listed in [hacks/lifecycle.md](../hacks/lifecycle.md); the owner's plan review. Not enforced by tooling.

## Production keeps its protections

- **Rule:** do not turn off RDS deletion protection, Multi-AZ, backups, ALB deletion protection or the secret recovery window in `prod` as a side effect of another change.
- **Reason:** they protect the production data and endpoints; `dev` runs without them on purpose to stay cheap and disposable (`guide/environments.md`, `guide/backup-and-dr.md`).
- **Where:** `infrastructure/environments/prod/terraform.tfvars`; `environment == "prod"` in `infrastructure/modules/load_balancer/main.tf`; the `prod/tests/*.tftest.hcl` runs; the Checkov skips that depend on these values (`guide/ci.md`, "Inline skips").
