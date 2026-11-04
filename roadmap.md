# Roadmap

## Done

- Bootstrap: remote state bucket with S3 lock file and KMS key
- Environments: shared `stack` module with `dev` and `prod` roots (see [Environments](docs/environments.md))
- Assets S3 bucket (served through CloudFront, see [Frontend Deployment](docs/frontend.md))
- Shared S3 bucket for ALB and CloudFront access logs (see [Security](docs/security.md))
- Observability: Prometheus, Grafana and Loki on EC2 with Cloud Map discovery (see [Observability](docs/observability.md))

## Open

See also the [prod-forge organization](https://github.com/prod-forge).

- Bootstrap: team management (not started; today access is set up by hand, see [Development Setup](docs/development-setup.md))
- Blue/Green Deployment: would replace the ECS rolling deployment with CodeDeploy shifting traffic between two ALB target groups, giving instant rollback at the cost of a second target group and a CD workflow change (design note in [docs/blue-green.md](docs/blue-green.md), not implemented)
- EKS: would replace the ECS cluster, service and task definition modules with a Kubernetes cluster, node groups or Fargate profiles and Helm releases, and move Cloud Map discovery to Kubernetes service discovery; the VPC, RDS, Redis, frontend and security modules would stay
- Terraform plan on pull requests: CI runs fmt, validate, tflint, checkov and terraform-docs but no `terraform plan`
- Pin GitHub Actions to commit SHAs
