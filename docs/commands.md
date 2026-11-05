# Commands

Commands for working with the infrastructure code. Human setup (AWS access, IAM Identity Center, bootstrap) is in
`guide/development-setup.md`. How to add a module, variable or output is in
[architecture/patterns.md](architecture/patterns.md).

## Tool versions

| Tool           | Version                      | Pinned in                                  |
| -------------- | ---------------------------- | ------------------------------------------ |
| Terraform      | 1.17.1 in CI (`required_version = ">= 1.10"`; tests need 1.11+) | `.github/workflows/terraform-ci.yml`, every `versions.tf` |
| TFLint         | 0.65.0, AWS ruleset 0.50.0   | `.github/workflows/terraform-ci.yml`, `.tflint.hcl` |
| terraform-docs | 0.24.0                       | `.github/workflows/terraform-ci.yml`       |
| Checkov        | `checkov-action@v12`         | `.github/workflows/terraform-ci.yml`, `.checkov.yaml` |

`terraform test` needs Terraform 1.11 or newer (`override_during`); see `guide/ci.md`.

---

## Local checks

None of these needs AWS credentials. Run from the repository root.

```bash
# Format (CI runs the -check form)
terraform fmt -recursive
terraform fmt -check -recursive

# Validate each root (bootstrap, dev, prod); -lockfile=readonly as in CI
terraform -chdir=bootstrap init -backend=false -lockfile=readonly
terraform -chdir=bootstrap validate
terraform -chdir=infrastructure/environments/dev init -backend=false -lockfile=readonly
terraform -chdir=infrastructure/environments/dev validate
terraform -chdir=infrastructure/environments/prod init -backend=false -lockfile=readonly
terraform -chdir=infrastructure/environments/prod validate

# Offline tests (prod root only, mock providers)
terraform -chdir=infrastructure/environments/prod test

# Lint and scan
tflint --init
tflint --recursive
# Checkov: use the image CI uses; a Homebrew checkov 3.4.3 skips the graph checks and reports zero
docker run --rm -v "$PWD":/w -w /w --entrypoint checkov ghcr.io/bridgecrewio/checkov:3.4.3 -d infrastructure --config-file .checkov.yaml --quiet --compact

# Module READMEs (one module)
terraform-docs -c .terraform-docs.yml infrastructure/modules/<module>

# Module READMEs (all, as CI does)
for d in $(find infrastructure/modules -name '*.tf' -exec dirname {} \; | sort -u); do
  terraform-docs -c "$PWD/.terraform-docs.yml" "$d"
done
```

## Plan (owner only)

`terraform plan` needs AWS credentials for the target account and is run by hand from an environment root, never in
CI and never by an agent:

```bash
export AWS_PROFILE=prod-forge   # guide/development-setup.md, "Configure Local AWS Profile"
terraform -chdir=infrastructure/environments/dev init
terraform -chdir=infrastructure/environments/dev plan
```

The same for `infrastructure/environments/prod`. Stop at any replacement the change did not intend
([hacks/lifecycle.md](hacks/lifecycle.md) lists the attributes that force one).

---

## What CI runs

`.github/workflows/terraform-ci.yml`, on every pull request and on push to `main`:

| Job              | Steps                                                                                                                  |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `fmt`            | `terraform fmt -check -recursive`                                                                                      |
| `validate`       | matrix over `bootstrap`, `infrastructure/environments/dev`, `infrastructure/environments/prod`: `terraform init -backend=false -lockfile=readonly`, `terraform validate`; `terraform test` in prod only |
| `tflint`         | `tflint --init`, `tflint --recursive`                                                                                  |
| `checkov`        | `checkov-action` on `infrastructure` with `.checkov.yaml`, `soft_fail: false`                                          |
| `terraform-docs` | regenerates the README of every directory under `infrastructure/modules` that contains `.tf` files, fails on any diff   |

CI has no AWS credentials: no `plan`, no `apply` (`guide/ci.md`).

---

## Git hooks

The hooks live in `.githooks/` and are enabled once per clone:

```bash
git config core.hooksPath .githooks
```

| Hook         | What it runs                                                                                                                     |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| `pre-commit` | `terraform fmt -check -recursive`; when `.tf`, `.tfvars` or `.hcl` files are staged, `init -backend=false` and `validate` in `bootstrap`, `infrastructure/environments/dev` and `infrastructure/environments/prod` |
| `commit-msg` | rejects `Co-Authored-By`, `Generated-by` or `Assisted-by` trailers that mention Claude or Anthropic; checks a Conventional Commits subject |
| `pre-push`   | `terraform test` in `infrastructure/environments/prod`; `tflint --recursive` when `tflint` is installed                           |

The hooks run `init -backend=false` themselves, so they never touch the remote state and need no AWS credentials. Checkov and the
terraform-docs drift check run only in CI. A failing hook is fixed, not skipped with `--no-verify`.

---

## What agents must never run

- `terraform apply` or `terraform destroy` in any root
- `terraform init` with a backend, `terraform state *`, `terraform import`, `terraform force-unlock`
- `terraform plan` (needs credentials; the owner runs it)
- any AWS CLI command that changes resources

Allowed: `terraform fmt`, `terraform init -backend=false`, `terraform validate`, `terraform test` (mock providers),
`tflint`, `checkov`, `terraform-docs`.

Never edit `*.tfstate`, `.terraform/`, `.terraform.lock.hcl` by hand, or the generated part of a module README. Never
read or commit the git-ignored key material in `infrastructure/vpn-key`, `infrastructure/openvpn`,
`infrastructure/ssh`.
