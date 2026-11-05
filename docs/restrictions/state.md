# State

## Remote state in S3 with the lock file

- **Rule:** every environment root uses the S3 backend with `use_lockfile = true` and `encrypt = true`, one key per root. Do not add `dynamodb_table` and do not switch a shared root to local state.
- **Reason:** the state of `dev` and `prod` is shared by everyone who applies; the S3 lock file (Terraform 1.10+) replaced the DynamoDB lock table, which was removed in the environments migration (`guide/development-setup.md`, "State Locking"; `guide/migration-to-environments.md`).
- **Where:** the `backend "s3"` block in `infrastructure/environments/<env>/versions.tf`; `required_version = ">= 1.10"` in every `versions.tf`. The prod key stays `infrastructure/terraform.tfstate`, the key of the former single root, so the live state was not copied ([architecture/overview.md](../architecture/overview.md#state-backend)).

## The bootstrap state is local

- **Rule:** `bootstrap/` has no backend block, and its `terraform.tfstate` is never committed.
- **Reason:** the bootstrap creates the state bucket itself, so it cannot store its state there (`guide/development-setup.md`, "Bootstrap Infrastructure").
- **Where:** comment in `bootstrap/versions.tf`; `.gitignore` (`terraform.tfstate`, `terraform.tfstate.backup`, `*.tfstate.*`).

## The state bucket resists deletion

- **Rule:** keep `prevent_destroy`, versioning, SSE-KMS and the deny-non-TLS policy on the state bucket.
- **Reason:** destroying the bucket while state exists leaves resources running in AWS with no way to manage them through Terraform; versioning keeps earlier state recoverable (`guide/destroy.md`, "Why Order Matters" and "Step 2 — Unlock the Bootstrap").
- **Where:** `aws_s3_bucket.terraform_state` and its `lifecycle { prevent_destroy = true }` in `bootstrap/main.tf`.

## No manual state changes

- **Rule:** never edit `*.tfstate` by hand, and never run `terraform state *`, `terraform import` or `terraform force-unlock`. The owner runs them when a runbook calls for it.
- **Reason:** state must stay consistent with AWS; the runbooks that need state commands (`guide/migration-to-environments.md`, `guide/backup-and-dr.md`, "Restore procedure") are run step by step by the owner, with a plan reviewed after each step.
- **Where:** `AGENTS.md` ("Terraform State Rules"), [commands.md](../commands.md#what-agents-must-never-run). Nothing in the tooling blocks these commands.

## State and plans are never committed

- **Rule:** do not commit state files, state copies or saved plans.
- **Reason:** state and plan files can contain secrets (generated passwords, PEM bodies).
- **Where:** `.gitignore` (`terraform.tfstate`, `*.tfstate.*`, `*.tfplan`, `*.plan`, `*-state-before-migration.json`).
