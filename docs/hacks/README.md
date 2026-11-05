# Hacks

Every place where the code takes a shortcut or makes a non-obvious decision, and why. Without this list an agent "cleans up" exactly the code that must stay as it is. Before removing a `lifecycle` block, a `depends_on`, a `#checkov:skip`, a stale-looking comment or a hard-coded value, check here.

- [observability.md](observability.md) — stale `docs/observability.md` mentions that must stay, the monitoring host user data, `source_hash` uploads.
- [lifecycle.md](lifecycle.md) — `ignore_changes`, `create_before_destroy` with `name_prefix`, `moved` blocks, `depends_on` on outputs.
- [aws.md](aws.md) — the logs bucket encryption, the ECR `initial` tag, the CloudTrail ARN built from parts, the OIDC provider owned by one environment, the VPN key files.

The `#checkov:skip` comments are listed with their reasons in `guide/ci.md` ("Inline skips"); they are not repeated here.

## Format

```markdown
## <Short name>

- **What:** the shortcut or decision.
- **Where:** file path(s).
- **Why:** the reason.
- **If cleaned up:** what breaks when someone "fixes" it.
```
