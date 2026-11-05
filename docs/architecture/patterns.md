# Patterns

How to add a module, a variable, an environment value or an output, and the conventions every change follows. Commands are in [commands.md](../commands.md).

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

## How to change an environment value

A value that already exists as a root variable is changed only in `infrastructure/environments/<env>/terraform.tfvars`.
Keep the comment next to the value accurate, and update the dev/prod table in
[overview.md](overview.md#how-dev-and-prod-differ) and the relevant `guide/` chapter (`guide/environments.md` lists the
differences for humans). Check the plan (run by the owner) for replacements: some attributes force a new resource
(see [hacks/lifecycle.md](../hacks/lifecycle.md)).

## How to add a module

1. Create `infrastructure/modules/<name>/` with `versions.tf` (copy from a sibling module), `variables.tf`, `main.tf`
   and, if needed, `outputs.tf`. Single responsibility, no provider blocks.
2. Call it from `infrastructure/modules/stack/main.tf`; if a CD workflow needs a value, add an output (below).
3. If the module creates optional resources, gate them with `count` on a boolean or on `var.domain_name != ""`, as
   `acm-certificate`, `dns` and `security-baseline` do.
4. Generate its README with `terraform-docs`, then run the commands in [commands.md](../commands.md). Add a
   `tests/*.tftest.hcl` run in the prod root when the module has logic worth asserting offline.
5. Update the module table in [modules.md](modules.md) and the relevant `guide/` chapter.

## How to add an output

1. `infrastructure/modules/<module>/outputs.tf`: add the output.
2. `infrastructure/modules/stack/outputs.tf`: re-export it.
3. `infrastructure/environments/dev/outputs.tf` and `prod/outputs.tf`: re-export it from `module.stack` (the two files
   are identical).
4. If CD consumes it, add it to [overview.md](overview.md#outputs-consumed-by-cd) and to the GitHub variable mapping in
   `guide/workflow.md#deploy-workflow-variables`; the owner copies the value into the GitHub variables of the backend or
   frontend repository by hand.

Keep outputs minimal (`AGENTS.md`, "Module Rules"). Never output a secret value; output the secret ARN instead.

---

## Renaming or moving a resource

Renaming or moving a resource address of a live environment needs a `moved` block (see
`infrastructure/environments/prod/moved.tf`), otherwise the resource is destroyed and recreated.
