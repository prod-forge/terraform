# Open Issues

Deferred known problems, so they are not rediscovered (or silently "fixed") in every session. Each entry links the GitHub issue that tracks it. When a problem is fixed, remove its line in the same change.

## GitHub issues

- [#1](https://github.com/prod-forge/terraform/issues/1) — Fix the RDS connections alarm wording: 80% is only right for dev. The threshold is 90 of about 112 connections in dev but 320 of about 450 in prod (about 71%); the alarm description, the variable descriptions and the prod `terraform.tfvars` comment claim 80% for both. Changing the alarm description changes a live alarm in place.
- [#2](https://github.com/prod-forge/terraform/issues/2) — Run `terraform plan` on pull requests. Needs a read-only OIDC role first; see [restrictions/ci-cd.md](../restrictions/ci-cd.md) ("CI is offline; applies are manual").
- [#3](https://github.com/prod-forge/terraform/issues/3) — Pin GitHub Actions to commit SHAs in `.github/workflows/terraform-ci.yml`.
- [#4](https://github.com/prod-forge/terraform/issues/4) — Bootstrap: manage team access with Terraform. A design comment in the issue comes first.
- [#5](https://github.com/prod-forge/terraform/issues/5) — Implement blue/green deployment with CodeDeploy. Designed in `guide/blue-green.md`, not implemented; touches the ECS service, the ALB and the backend CD workflow.

Issues #2–#5 are also items of the public roadmap, [roadmap.md](../../roadmap.md).

## Without an issue

- [branch-protection.md](branch-protection.md) — `main` has no branch protection, so CI does not block merges.
- [dev-cd-workflows.md](dev-cd-workflows.md) — no backend or frontend CD workflow deploys dev; CD deploys prod only.
- [vpn-ca-key-in-state.md](vpn-ca-key-in-state.md) — the Client VPN CA private key is imported into ACM and kept in Terraform state.

## Format

One line per problem: the issue link, its title and, when the docs already describe it, a link to that note. A problem without an issue gets a short file in this folder: what is wrong, where, why it is deferred, and what a fix needs.
