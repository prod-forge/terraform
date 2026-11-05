# Developer's Guide

Human setup (AWS access, IAM Identity Center, bootstrap) is in `guide/development-setup.md`. This file is the
command and change reference.

## Tool versions

| Tool           | Version                      | Pinned in                                  |
| -------------- | ---------------------------- | ------------------------------------------ |
| Terraform      | 1.11.2 (`required_version = ">= 1.10"`) | `.github/workflows/terraform-ci.yml`, every `versions.tf` |
| TFLint         | 0.65.0, AWS ruleset 0.38.0   | `.github/workflows/terraform-ci.yml`, `.tflint.hcl` |
| terraform-docs | 0.24.0                       | `.github/workflows/terraform-ci.yml`       |
| Checkov        | `checkov-action@v12`         | `.github/workflows/terraform-ci.yml`, `.checkov.yaml` |

`terraform test` needs Terraform 1.11 or newer (`override_during`); see `guide/ci.md`.

---

## Commands

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
checkov -d infrastructure --config-file .checkov.yaml

# Module READMEs (one module)
terraform-docs -c .terraform-docs.yml infrastructure/modules/<module>

# Module READMEs (all, as CI does)
for d in $(find infrastructure/modules -name '*.tf' -exec dirname {} \; | sort -u); do
  terraform-docs -c "$PWD/.terraform-docs.yml" "$d"
done
```

`terraform plan` needs AWS credentials for the target account and is run by hand from an environment root, never in
CI.

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

## Conventions

- Every root and module has `versions.tf` and `variables.tf`; `main.tf` and `outputs.tf` where there are resources or
  outputs. Larger modules split resources into extra files (`vpc/endpoints.tf`, `vpc/flow_logs.tf`,
  `ecs-service/autoscaling.tf`, `rds/parameter-group.tf`).
- Modules declare `required_version` and `required_providers` only; providers, backend and `default_tags` live in the
  environment root's `versions.tf`. A module that needs `us-east-1` receives `aws.us_east_1` from the `stack` module
  (`providers = { aws = aws.us_east_1 }`).
- Module READMEs are generated: everything between `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` comes from
  `.terraform-docs.yml` (inject mode, sorted by name). Never hand-edit it; regenerate.
- `.terraform.lock.hcl` is committed for every root. CI inits with `-lockfile=readonly`, so a provider change needs
  the lock file updated in the same change.
- Resource names use the `${project}-${environment}` prefix (`local.name` in `modules/stack/main.tf`).

---

## How to add a variable

A setting that differs per environment flows root → stack → module:

1. `infrastructure/modules/<module>/variables.tf`: add the variable with `type` and `description` (and `validation`
   where the value has constraints); use it in the module.
2. `infrastructure/modules/stack/variables.tf`: add the stack-level variable (prefixed by the module, e.g.
   `rds_instance_class`).
3. `infrastructure/modules/stack/main.tf`: pass it to the module call.
4. `infrastructure/environments/dev/variables.tf` and `prod/variables.tf`: add the same variable (the two files are
   identical).
5. `infrastructure/environments/dev/main.tf` and `prod/main.tf`: pass it to `module "stack"`.
6. `infrastructure/environments/dev/terraform.tfvars` and `prod/terraform.tfvars`: set the value.
7. Regenerate the READMEs of the changed modules (including `stack`) with `terraform-docs`.

A value that is the same everywhere stays a module default or a local; it does not need the root plumbing.

## How to add a module

1. Create `infrastructure/modules/<name>/` with `versions.tf` (copy from a sibling module), `variables.tf`, `main.tf`
   and, if needed, `outputs.tf`. Single responsibility, no provider blocks.
2. Call it from `infrastructure/modules/stack/main.tf`; if a CD workflow needs a value, add an output to
   `modules/stack/outputs.tf` and re-export it in both `infrastructure/environments/<env>/outputs.tf`.
3. If the module creates optional resources, gate them with `count` on a boolean or on `var.domain_name != ""`, as
   `acm-certificate`, `dns` and `security-baseline` do.
4. Generate its README with `terraform-docs`, then run the commands above. Add a `tests/*.tftest.hcl` run in the prod
   root when the module has logic worth asserting offline.
5. Update `docs/architecture.md` (module table) and the relevant `guide/` chapter.

Renaming or moving a resource address of a live environment needs a `moved` block (see
`infrastructure/environments/prod/moved.tf`), otherwise the resource is destroyed and recreated.

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
