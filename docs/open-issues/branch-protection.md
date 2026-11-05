# `main` has no branch protection

- **What:** CI (`fmt`, `validate`, `terraform test`, TFLint, Checkov, the terraform-docs drift check, actionlint) runs on every pull request and on `main`, but nothing makes it a merge gate. `main` has no branch protection and no ruleset, so a red CI run does not block a merge or a direct push.
- **Where:** the GitHub settings of `prod-forge/terraform`; the jobs in `.github/workflows/terraform-ci.yml` (`guide/ci.md`).
- **Why deferred:** the owner decided on 2026-11-05 not to enable protection yet; changes are kept green by review and the local git hooks (`.githooks/`).
- **What a fix needs:** a branch protection rule or ruleset on `main` with the CI jobs as required status checks (and pull requests required), set by the repository owner; then reword `docs/goal.md` back to "cannot be merged".
