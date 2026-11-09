# Repository

## English only

- **Rule:** code, comments, docs and the guide are written in English.
- **Where:** `cspell.json` (`"language": "en,en-GB"`). It is not run by a hook; check docs manually with `npx --yes cspell --no-progress 'docs/**/*.md'`.

## Commit messages

- **Rule:** Conventional Commits; allowed types are `ci`, `chore`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`. No `Co-Authored-By` or other AI attribution in commits or pull requests.
- **Reason:** one commit format across the Prod Forge repositories (`CONTRIBUTING.md`, "Commit your changes"); the attribution policy is the same as in the backend and frontend repositories.
- **Where:** `.githooks/commit-msg` checks the subject and rejects `Co-Authored-By`, `Generated-by` or `Assisted-by` trailers that mention Claude or Anthropic ([commands.md](../commands.md#git-hooks)).

## CHANGELOG.md is written by hand at release time

- **Rule:** edit `CHANGELOG.md` only for a release, when the owner asks: add one section for the new version above the previous one and never rewrite released sections.
- **Reason:** there is no release tooling in this repository, so the entry is written by hand from the commits since the last tag; released sections record what shipped.

## Generated files

- **Rule:** never hand-edit the part of a module `README.md` between `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->`; regenerate it with `terraform-docs`.
- **Reason:** it is generated from the variables and outputs; a hand edit is overwritten and fails the drift check.
- **Where:** `.terraform-docs.yml`; the `terraform-docs` CI job fails on any diff.

## Protected files

- **Rule:** do not edit `*.tfstate`, `.terraform/`, `.terraform.lock.hcl` or `.env*` files.
- **Reason:** state, provider caches and lock files are managed by Terraform; `.env*` files may hold secrets.
- **Where:** `AGENTS.md` ("Ignore Rules"), [commands.md](../commands.md#what-agents-must-never-run). Not enforced by tooling.

## Git hooks are the first gate

- **Rule:** a commit or push that fails the hooks is fixed, not forced through (`--no-verify` is not used).
- **Reason:** the hooks run part of the offline CI checks ([ci-cd.md](ci-cd.md)) before a push.
- **Where:** `.githooks/pre-commit`, `.githooks/commit-msg`, `.githooks/pre-push`, enabled with `git config core.hooksPath .githooks` ([commands.md](../commands.md#git-hooks)).

## docs/ is not formatted by Prettier

- **Rule:** keep `docs/` out of Prettier.
- **Reason:** these files are written and edited by agents; Prettier has broken their tables, nested lists and checkboxes (the same rule as in the backend and frontend repositories, backend `guide/ai-development.md`, "Context belongs to the repository").
- **Where:** `.prettierignore` (`docs/`).
