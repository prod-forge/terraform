# Restrictions

Constraints of this project. Each entry gives the rule, the reason and where it is enforced. Read these before writing a plan. The rule lists in `AGENTS.md` stay the rules file; these entries explain why the rules that matter most exist.

- [state.md](state.md) — remote S3 state with the lock file, local bootstrap state, no manual state edits.
- [aws-safety.md](aws-safety.md) — no apply, destroy or plan by agents, secrets and key material, no unintended replacements.
- [ci-cd.md](ci-cd.md) — offline CI on every pull request, manual applies, outputs copied into GitHub variables.
- [repository.md](repository.md) — English, commit messages, generated and protected files, git hooks.
