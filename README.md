<p align="center">
  <img alt="Prod Forge" src="https://raw.githubusercontent.com/prod-forge/.github/main/assets/prod-forge-logo.png" width="264px" height="243px">
</p>

_AI made writing the code easy. Running it in production is still hard._

This repository describes the AWS infrastructure for Prod Forge as Terraform code: environments, networking, ECS, RDS, ElastiCache, the frontend hosting and the observability stack. It answers: how do I run all of it on AWS with code, not clicks?

Part of Prod Forge — start with the organization overview: https://github.com/prod-forge

## Stack

| Layer          | Tools                                            |
| -------------- | ------------------------------------------------ |
| Deploy         | AWS S3 · CloudFront · ECR · ECS                  |
| Infrastructure | Terraform · AWS · RDS · ElastiCache              |
| Observability  | Prometheus · Grafana · Loki · Promtail · Tempo   |

The full stack table is on the organization page: https://github.com/prod-forge

## Getting started

Start with the [Development Setup](docs/development-setup.md).

# Table of contents

- [1. Development Setup](docs/development-setup.md)
  - [IDE Setup (WebStorm)](docs/development-setup.md#ide-setup-webstorm)
    - [Install Terraform plugin](docs/development-setup.md#install-terraform-plugin)
    - [Configure Terraform formatting watcher](docs/development-setup.md#configure-terraform-formatting-watcher)
  - [Preparing AWS Access](docs/development-setup.md#preparing-aws-access)
    - [Setting up IAM Identity Center](docs/development-setup.md#setting-up-iam-identity-center)
    - [Configure Local AWS Profile](docs/development-setup.md#configure-local-aws-profile)
  - [Verify AWS Connection](docs/development-setup.md#verify-aws-connection)
  - [Global Terraform State](docs/development-setup.md#global-terraform-state)
  - [State Locking](docs/development-setup.md#state-locking)
  - [Bootstrap Infrastructure](docs/development-setup.md#bootstrap-infrastructure)

<!-- -->

- [2. Environments](docs/environments.md)
  - [Environment Strategy](docs/environments.md#environment-strategy)
    - [Development Environment (dev)](docs/environments.md#development-environment-dev)
    - [Production Environment (prod)](docs/environments.md#production-environment-prod)
    - [Why Not Use Pre-Production?](docs/environments.md#why-not-use-pre-production)
  - [Key Principle](docs/environments.md#key-principle)
  - [Layout in the Code](docs/environments.md#layout-in-the-code)
    - [Differences Between dev and prod](docs/environments.md#differences-between-dev-and-prod)
    - [One AWS Account or Two](docs/environments.md#one-aws-account-or-two)
  - [Creating dev](docs/environments.md#creating-dev)
  - [Cost per Environment](docs/environments.md#cost-per-environment)

<!-- -->

- [3. Workflow](docs/workflow.md)
  - [Amazon ECR](docs/workflow.md#amazon-ecr)
    - [The "Chicken-and-Egg" Dilemma](docs/workflow.md#the-chicken-and-egg-dilemma)
    - [Initial Application Image](docs/workflow.md#initial-application-image)
      - [Required Endpoints](docs/workflow.md#required-endpoints)
  - [AWS Secrets Manager](docs/workflow.md#aws-secrets-manager)
    - [Generated secrets](docs/workflow.md#generated-secrets)
  - [GitHub Integration for CI/CD](docs/workflow.md#github-integration-for-cicd)
    - [Approaches](docs/workflow.md#approaches)
      - [1. Dedicated AWS User](docs/workflow.md#1-dedicated-aws-user)
      - [2. OpenID Connect (OIDC) - Recommended](docs/workflow.md#2-openid-connect-oidc---recommended)
    - [Terraform Setup](docs/workflow.md#terraform-setup)
    - [Roles and trust conditions](docs/workflow.md#roles-and-trust-conditions)
    - [Rollout notes](docs/workflow.md#rollout-notes)
    - [Deploy workflow variables](docs/workflow.md#deploy-workflow-variables)
    - [Why OIDC is Recommended](docs/workflow.md#why-oidc-is-recommended)
  - [ECS Cluster](docs/workflow.md#ecs-cluster)
    - [Networking](docs/workflow.md#networking)
  - [Application Load Balancer (ALB)](docs/workflow.md#application-load-balancer-alb)
  - [ECS Service](docs/workflow.md#ecs-service)
    - [IAM](docs/workflow.md#iam)
  - [Task Definition](docs/workflow.md#task-definition)
    - [Backend configuration](docs/workflow.md#backend-configuration)
  - [Redis](docs/workflow.md#redis)
  - [One-Run ECS Tasks](docs/workflow.md#one-run-ecs-tasks)

<!-- -->

- [4. Frontend Deployment](docs/frontend.md)
  - [Architecture](docs/frontend.md#architecture)
  - [Custom Domain](docs/frontend.md#custom-domain)
  - [WAF and Access Logs](docs/frontend.md#waf-and-access-logs)
  - [Security Headers](docs/frontend.md#security-headers)
  - [SPA Routing](docs/frontend.md#spa-routing)
  - [Cache Strategy](docs/frontend.md#cache-strategy)
  - [Deployment](docs/frontend.md#deployment)
  - [Rollback](docs/frontend.md#rollback)
  - [Terraform Setup](docs/frontend.md#terraform-setup)
  - [GitHub Actions Integration](docs/frontend.md#github-actions-integration)
  - [Advantages](docs/frontend.md#advantages)
  - [Limitations](docs/frontend.md#limitations)

<!-- -->

- [5. Observability](docs/observability.md)
  - [Deployment Model](docs/observability.md#deployment-model)
  - [Why EC2?](docs/observability.md#why-ec2)
  - [Observability Data Flow](docs/observability.md#observability-data-flow)
  - [Advantages of This Approach](docs/observability.md#advantages-of-this-approach)
    - [Simplicity](docs/observability.md#simplicity)
    - [Cost Efficiency](docs/observability.md#cost-efficiency)
    - [Full Control](docs/observability.md#full-control)
    - [Infrastructure Independence](docs/observability.md#infrastructure-independence)
  - [Limitations](docs/observability.md#limitations)
    - [Single Point of Failure](docs/observability.md#single-point-of-failure)
    - [Scaling Limitations](docs/observability.md#scaling-limitations)
    - [Operational Maintenance](docs/observability.md#operational-maintenance)
  - [When to Use Managed Observability](docs/observability.md#when-to-use-managed-observability)

<!-- -->

- [6. Debugging](docs/debugging.md)
  - [ECS / Fargate Debugging](docs/debugging.md#ecs--fargate-debugging)
    - [Inspect ECS Tasks](docs/debugging.md#inspect-ecs-tasks)
    - [Execute Commands Inside Container](docs/debugging.md#execute-commands-inside-container)
  - [RDS, Redis Debugging (OpenVPN)](docs/debugging.md#rds-redis-debugging-openvpn)
    - [Install OpenVPN](docs/debugging.md#install-openvpn)
    - [Generate Certificates](docs/debugging.md#generate-certificates)
    - [Generate Client Certificate](docs/debugging.md#generate-client-certificate)
    - [Generate VPN Client Configuration](docs/debugging.md#generate-vpn-client-configuration)
    - [Verify VPN Connection](docs/debugging.md#verify-vpn-connection)
    - [Connect to RDS or Redis](docs/debugging.md#connect-to-rds-or-redis)
  - [Monitoring host access (SSM Session Manager)](docs/debugging.md#monitoring-host-access-ssm-session-manager)
    - [Debugging bootstrap.sh](docs/debugging.md#debugging-bootstrapsh)

<!-- -->

- [7. Troubleshooting](docs/troubleshooting.md)
  - [EC2/ECS + RDS Network Routing Connection](docs/troubleshooting.md#ec2ecs--rds-network-routing-connection)

<!-- -->

- [8. Destroying the Infrastructure](docs/destroy.md)
  - [Why Order Matters](docs/destroy.md#why-order-matters)
  - [Step 1 — Destroy Infrastructure](docs/destroy.md#step-1--destroy-infrastructure)
  - [Step 2 — Unlock the Bootstrap](docs/destroy.md#step-2--unlock-the-bootstrap)
  - [Step 3 — Delete the IAM User](docs/destroy.md#step-3--delete-the-iam-user)

<!-- -->

- [9. CI for Infrastructure](docs/ci.md)
  - [Jobs](docs/ci.md#jobs)
  - [Reproducibility](docs/ci.md#reproducibility)
  - [Running locally](docs/ci.md#running-locally)
  - [Tests](docs/ci.md#tests)
  - [Why there is no terraform plan in CI yet](docs/ci.md#why-there-is-no-terraform-plan-in-ci-yet)
  - [Baseline](docs/ci.md#baseline)
    - [Inline skips](docs/ci.md#inline-skips)

<!-- -->

- [10. Backup and Disaster Recovery](docs/backup-and-dr.md)
  - [Protection in place](docs/backup-and-dr.md#protection-in-place)
  - [Objectives](docs/backup-and-dr.md#objectives)
  - [Restore procedure](docs/backup-and-dr.md#restore-procedure)
  - [Quarterly restore drill](docs/backup-and-dr.md#quarterly-restore-drill)
  - [Not covered](docs/backup-and-dr.md#not-covered)

<!-- -->

- [11. Scaling](docs/scaling.md)
  - [Capacity model](docs/scaling.md#capacity-model)
  - [Scaling policies](docs/scaling.md#scaling-policies)
  - [Deployments and shutdown](docs/scaling.md#deployments-and-shutdown)
  - [Health checks: liveness vs readiness](docs/scaling.md#health-checks-liveness-vs-readiness)
  - [How to load-test the policies](docs/scaling.md#how-to-load-test-the-policies)
  - [Fargate Spot trade-off](docs/scaling.md#fargate-spot-trade-off)

<!-- -->

- [12. Security](docs/security.md)
  - [TLS everywhere](docs/security.md#tls-everywhere)
    - [Without a domain (insecure fallback)](docs/security.md#without-a-domain-insecure-fallback)
  - [WAF](docs/security.md#waf)
  - [Response headers](docs/security.md#response-headers)
  - [Load balancer hardening](docs/security.md#load-balancer-hardening)
  - [Metrics endpoints](docs/security.md#metrics-endpoints)
  - [Access logs](docs/security.md#access-logs)
  - [Security groups](docs/security.md#security-groups)
  - [IAM](docs/security.md#iam)
  - [Monitoring host](docs/security.md#monitoring-host)
  - [Account security baseline](docs/security.md#account-security-baseline)
  - [Known gaps](docs/security.md#known-gaps)

<!-- -->

- [13. Cost](docs/cost.md)
  - [Monthly Estimate](docs/cost.md#monthly-estimate)
  - [Budget](docs/cost.md#budget)
  - [Main Levers](docs/cost.md#main-levers)

<!-- -->

- [14. Migration to the Environments Layout](docs/migration-to-environments.md)
  - [What Stays the Same](docs/migration-to-environments.md#what-stays-the-same)
  - [Moved Addresses](docs/migration-to-environments.md#moved-addresses)
  - [What Is Replaced](docs/migration-to-environments.md#what-is-replaced)
  - [Rollout](docs/migration-to-environments.md#rollout)
  - [Expected Downtime](docs/migration-to-environments.md#expected-downtime)
  - [Rollback](docs/migration-to-environments.md#rollback)

<!-- -->

- [15. Blue/Green Deployment (design note, not implemented)](docs/blue-green.md)
  - [Why](docs/blue-green.md#why)
  - [What changes in the service](docs/blue-green.md#what-changes-in-the-service)
  - [What changes in the CD workflow](docs/blue-green.md#what-changes-in-the-cd-workflow)
  - [Trade-offs](docs/blue-green.md#trade-offs)

# Contributing

We welcome any kind of contribution, please read the guidelines:

[CONTRIBUTING](CONTRIBUTING.md)

# The MIT License

[LICENSE](LICENSE)
