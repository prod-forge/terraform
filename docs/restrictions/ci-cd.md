# CI and CD

## CI must stay green

- **Rule:** every pull request and every push to `main` passes CI; a red job is fixed, not skipped.
- **Reason:** CI is the only gate that runs Checkov and the terraform-docs drift check, and it validates every root with the committed lock files (`guide/ci.md`, "Jobs").
- **Where:** `.github/workflows/terraform-ci.yml` — `fmt`, `validate` (matrix over `bootstrap`, `dev`, `prod`; `terraform test` in prod), `tflint`, `checkov`, `terraform-docs`.

## CI is offline; applies are manual

- **Rule:** do not add AWS credentials, a `plan` or an `apply` step to CI without an approved plan.
- **Reason:** a plan needs a read-only OIDC role with access to the state bucket, which does not exist yet; apply stays a manual, reviewed step (`guide/ci.md`, "Why there is no `terraform plan` in CI yet"; GitHub issue #2).
- **Where:** `.github/workflows/terraform-ci.yml` (`permissions: contents: read`, no AWS steps).

## Checkov findings are fixed or skipped with a reason

- **Rule:** keep `skip-check` in `.checkov.yaml` empty. A new finding is fixed, or skipped inline with `#checkov:skip=<ID>: <reason>` and added to the table in `guide/ci.md`.
- **Reason:** a global skip hides the check for every future resource; an inline skip documents why this resource is an exception (`guide/ci.md`, "Inline skips").
- **Where:** `.checkov.yaml` (`skip-check: []`), the `checkov` job (`soft_fail: false`).

## Deploy roles and outputs are a contract with the other repositories

- **Rule:** do not rename an output consumed by CD, a deploy role, or the migration task family without the matching change in the backend or frontend repository.
- **Reason:** the outputs are copied by hand into GitHub variables of the backend and frontend repositories; each deploy role trusts only jobs of its own repository that run in its GitHub environment (`guide/workflow.md`, "Roles and trust conditions" and "Deploy workflow variables").
- **Where:** `infrastructure/environments/<env>/outputs.tf`, `infrastructure/modules/github-oidc/main.tf`; `prod/tests/github-oidc.tftest.hcl` asserts the trust conditions. The consumed outputs are listed in [architecture/overview.md](../architecture/overview.md#outputs-consumed-by-cd).

## Provider versions come from the lock files

- **Rule:** a provider upgrade updates `.terraform.lock.hcl` of every root in the same change; never edit a lock file by hand.
- **Reason:** CI inits with `-lockfile=readonly` and fails when the lock file does not match the constraints (`guide/ci.md`, "Reproducibility").
- **Where:** `.terraform.lock.hcl` in `bootstrap/`, `infrastructure/environments/dev/`, `infrastructure/environments/prod/`; the `validate` job.
