# Changelog

## 1.0.0 (2026-11-04)

First published version of the Prod Forge infrastructure: Terraform for the backend, the frontend and the observability
stack on AWS, laid out as a shared `stack` module with `dev` and `prod` environment roots. There are no earlier tags.

### Infrastructure

- Environments layout: `bootstrap` for the state backend, a shared `stack` module and `environments/dev` and
  `environments/prod` roots, default tags, S3 lockfile only.
- RDS PostgreSQL: multi-AZ, encryption, automated backups, deletion protection, custom parameter group.
- ElastiCache Redis: replication group with automatic failover, TLS, AUTH token and snapshots.
- ECS: private networking with NAT and VPC endpoints, autoscaling, deployment circuit breaker, container insights,
  every backend config variable passed to the app and migration tasks.
- Edge: HTTPS with ACM and redirect when a domain is set, WAF, hardened ALB and CloudFront, DNS records.
- Frontend: S3 buckets for the web client and assets, CloudFront with a security response headers policy that serves
  the full Content Security Policy.
- Outputs expose the names the backend and frontend deploy workflows need.

### Observability

- Prometheus, Grafana, Loki, Promtail and Tempo provisioned on a hardened SSM-only monitoring host with Cloud Map
  service discovery; alerts, dashboards and Promtail config synced from the backend.
- CloudWatch alarms, SNS notifications and an account-wide budget owned by `prod`.

### Security

- CloudTrail, GuardDuty and IAM Access Analyzer baseline.
- Separate scoped GitHub OIDC roles per repository that trust only the `prod` environment subject; immutable, scanned
  ECR; SSO-based developer access.
- Secrets Manager entries ordered before their consumers; TLS-only config bucket policy.

### CI

- `terraform fmt`, `validate`, tflint, checkov and a terraform-docs check on pull requests and pushes to `main`;
  versions aligned with local tooling.

### Documentation

- Infrastructure guide with renumbered chapters, a blue/green design note and a mixed-content caveat for the
  no-domain API origin, aligned with the code.
- cspell dictionary, roadmap, contributing guide, MIT license.
