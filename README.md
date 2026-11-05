<p align="center">
  <img alt="Prod Forge" src="https://raw.githubusercontent.com/prod-forge/.github/main/assets/prod-forge-logo.png" width="264px" height="243px">
</p>

_AI made writing the code easy. Running it in production is still hard._

This repository describes the AWS infrastructure for Prod Forge as Terraform code: environments, networking, ECS, RDS, ElastiCache, the frontend hosting and the observability stack. It answers: how do I run all of it on AWS with code, not clicks?

Part of Prod Forge — start with the organization overview: https://github.com/prod-forge

## Stack

| Layer          | Tools                                          |
| -------------- | ---------------------------------------------- |
| Deploy         | AWS S3 · CloudFront · ECR · ECS                |
| Infrastructure | Terraform · AWS · RDS · ElastiCache            |
| Observability  | Prometheus · Grafana · Loki · Promtail · Tempo |

The full stack table is on the organization page: https://github.com/prod-forge

## Getting started

Start with the [Development Setup](guide/development-setup.md).

# Table of contents

- [1. Development Setup](guide/development-setup.md)
  - [IDE Setup (WebStorm)](guide/development-setup.md#ide-setup-webstorm)
    - [Install Terraform plugin](guide/development-setup.md#install-terraform-plugin)
    - [Configure Terraform formatting watcher](guide/development-setup.md#configure-terraform-formatting-watcher)
  - [Preparing AWS Access](guide/development-setup.md#preparing-aws-access)
    - [Setting up IAM Identity Center](guide/development-setup.md#setting-up-iam-identity-center)
    - [Configure Local AWS Profile](guide/development-setup.md#configure-local-aws-profile)
  - [Verify AWS Connection](guide/development-setup.md#verify-aws-connection)
  - [Global Terraform State](guide/development-setup.md#global-terraform-state)
  - [State Locking](guide/development-setup.md#state-locking)
  - [Bootstrap Infrastructure](guide/development-setup.md#bootstrap-infrastructure)

<!-- -->

- [2. Environments](guide/environments.md)
  - [Environment Strategy](guide/environments.md#environment-strategy)
    - [Development Environment (dev)](guide/environments.md#development-environment-dev)
    - [Production Environment (prod)](guide/environments.md#production-environment-prod)
    - [Why Not Use Pre-Production?](guide/environments.md#why-not-use-pre-production)
  - [Key Principle](guide/environments.md#key-principle)
  - [Layout in the Code](guide/environments.md#layout-in-the-code)
    - [Differences Between dev and prod](guide/environments.md#differences-between-dev-and-prod)
    - [One AWS Account or Two](guide/environments.md#one-aws-account-or-two)
  - [Creating dev](guide/environments.md#creating-dev)
  - [Cost per Environment](guide/environments.md#cost-per-environment)

<!-- -->

- [3. Workflow](guide/workflow.md)
  - [Amazon ECR](guide/workflow.md#amazon-ecr)
    - [The "Chicken-and-Egg" Dilemma](guide/workflow.md#the-chicken-and-egg-dilemma)
    - [Initial Application Image](guide/workflow.md#initial-application-image)
      - [Required Endpoints](guide/workflow.md#required-endpoints)
  - [AWS Secrets Manager](guide/workflow.md#aws-secrets-manager)
    - [Generated secrets](guide/workflow.md#generated-secrets)
  - [GitHub Integration for CI/CD](guide/workflow.md#github-integration-for-cicd)
    - [Approaches](guide/workflow.md#approaches)
      - [1. Dedicated AWS User](guide/workflow.md#1-dedicated-aws-user)
      - [2. OpenID Connect (OIDC) - Recommended](guide/workflow.md#2-openid-connect-oidc---recommended)
    - [Terraform Setup](guide/workflow.md#terraform-setup)
    - [Roles and trust conditions](guide/workflow.md#roles-and-trust-conditions)
    - [Rollout notes](guide/workflow.md#rollout-notes)
    - [Deploy workflow variables](guide/workflow.md#deploy-workflow-variables)
    - [Why OIDC is Recommended](guide/workflow.md#why-oidc-is-recommended)
  - [ECS Cluster](guide/workflow.md#ecs-cluster)
    - [Networking](guide/workflow.md#networking)
  - [Application Load Balancer (ALB)](guide/workflow.md#application-load-balancer-alb)
  - [ECS Service](guide/workflow.md#ecs-service)
    - [IAM](guide/workflow.md#iam)
  - [Task Definition](guide/workflow.md#task-definition)
    - [Backend configuration](guide/workflow.md#backend-configuration)
  - [Redis](guide/workflow.md#redis)
  - [One-Run ECS Tasks](guide/workflow.md#one-run-ecs-tasks)

<!-- -->

- [4. Frontend Deployment](guide/frontend.md)
  - [Architecture](guide/frontend.md#architecture)
  - [Custom Domain](guide/frontend.md#custom-domain)
  - [WAF and Access Logs](guide/frontend.md#waf-and-access-logs)
  - [Security Headers](guide/frontend.md#security-headers)
  - [SPA Routing](guide/frontend.md#spa-routing)
  - [Cache Strategy](guide/frontend.md#cache-strategy)
  - [Deployment](guide/frontend.md#deployment)
  - [Rollback](guide/frontend.md#rollback)
  - [Terraform Setup](guide/frontend.md#terraform-setup)
  - [GitHub Actions Integration](guide/frontend.md#github-actions-integration)
  - [Advantages](guide/frontend.md#advantages)
  - [Limitations](guide/frontend.md#limitations)

<!-- -->

- [5. Observability](guide/observability.md)
  - [Deployment Model](guide/observability.md#deployment-model)
  - [Why EC2?](guide/observability.md#why-ec2)
  - [Observability Data Flow](guide/observability.md#observability-data-flow)
  - [Advantages of This Approach](guide/observability.md#advantages-of-this-approach)
    - [Simplicity](guide/observability.md#simplicity)
    - [Cost Efficiency](guide/observability.md#cost-efficiency)
    - [Full Control](guide/observability.md#full-control)
    - [Infrastructure Independence](guide/observability.md#infrastructure-independence)
  - [Limitations](guide/observability.md#limitations)
    - [Single Point of Failure](guide/observability.md#single-point-of-failure)
    - [Scaling Limitations](guide/observability.md#scaling-limitations)
    - [Operational Maintenance](guide/observability.md#operational-maintenance)
  - [When to Use Managed Observability](guide/observability.md#when-to-use-managed-observability)

<!-- -->

- [6. Debugging](guide/debugging.md)
  - [ECS / Fargate Debugging](guide/debugging.md#ecs--fargate-debugging)
    - [Inspect ECS Tasks](guide/debugging.md#inspect-ecs-tasks)
    - [Execute Commands Inside Container](guide/debugging.md#execute-commands-inside-container)
  - [RDS, Redis Debugging (OpenVPN)](guide/debugging.md#rds-redis-debugging-openvpn)
    - [Install OpenVPN](guide/debugging.md#install-openvpn)
    - [Generate Certificates](guide/debugging.md#generate-certificates)
    - [Generate Client Certificate](guide/debugging.md#generate-client-certificate)
    - [Generate VPN Client Configuration](guide/debugging.md#generate-vpn-client-configuration)
    - [Verify VPN Connection](guide/debugging.md#verify-vpn-connection)
    - [Connect to RDS or Redis](guide/debugging.md#connect-to-rds-or-redis)
  - [Monitoring host access (SSM Session Manager)](guide/debugging.md#monitoring-host-access-ssm-session-manager)
    - [Debugging bootstrap.sh](guide/debugging.md#debugging-bootstrapsh)

<!-- -->

- [7. Troubleshooting](guide/troubleshooting.md)
  - [EC2/ECS + RDS Network Routing Connection](guide/troubleshooting.md#ec2ecs--rds-network-routing-connection)

<!-- -->

- [8. Destroying the Infrastructure](guide/destroy.md)
  - [Why Order Matters](guide/destroy.md#why-order-matters)
  - [Step 1 — Destroy Infrastructure](guide/destroy.md#step-1--destroy-infrastructure)
  - [Step 2 — Unlock the Bootstrap](guide/destroy.md#step-2--unlock-the-bootstrap)
  - [Step 3 — Remove Operator Access](guide/destroy.md#step-3--remove-operator-access)

<!-- -->

- [9. CI for Infrastructure](guide/ci.md)
  - [Jobs](guide/ci.md#jobs)
  - [Reproducibility](guide/ci.md#reproducibility)
  - [Running locally](guide/ci.md#running-locally)
  - [Git hooks](guide/ci.md#git-hooks)
  - [Tests](guide/ci.md#tests)
  - [Why there is no terraform plan in CI yet](guide/ci.md#why-there-is-no-terraform-plan-in-ci-yet)
  - [Baseline](guide/ci.md#baseline)
    - [Inline skips](guide/ci.md#inline-skips)

<!-- -->

- [10. Backup and Disaster Recovery](guide/backup-and-dr.md)
  - [Protection in place](guide/backup-and-dr.md#protection-in-place)
  - [Objectives](guide/backup-and-dr.md#objectives)
  - [Restore procedure](guide/backup-and-dr.md#restore-procedure)
  - [Quarterly restore drill](guide/backup-and-dr.md#quarterly-restore-drill)
  - [Not covered](guide/backup-and-dr.md#not-covered)

<!-- -->

- [11. Scaling](guide/scaling.md)
  - [Capacity model](guide/scaling.md#capacity-model)
  - [Scaling policies](guide/scaling.md#scaling-policies)
  - [Deployments and shutdown](guide/scaling.md#deployments-and-shutdown)
  - [Health checks: liveness vs readiness](guide/scaling.md#health-checks-liveness-vs-readiness)
  - [How to load-test the policies](guide/scaling.md#how-to-load-test-the-policies)
  - [Fargate Spot trade-off](guide/scaling.md#fargate-spot-trade-off)

<!-- -->

- [12. Security](guide/security.md)
  - [TLS everywhere](guide/security.md#tls-everywhere)
    - [Without a domain (insecure fallback)](guide/security.md#without-a-domain-insecure-fallback)
  - [WAF](guide/security.md#waf)
  - [Response headers](guide/security.md#response-headers)
  - [Load balancer hardening](guide/security.md#load-balancer-hardening)
  - [Metrics endpoints](guide/security.md#metrics-endpoints)
  - [Access logs](guide/security.md#access-logs)
  - [Security groups](guide/security.md#security-groups)
  - [IAM](guide/security.md#iam)
  - [Monitoring host](guide/security.md#monitoring-host)
  - [Account security baseline](guide/security.md#account-security-baseline)
  - [Known gaps](guide/security.md#known-gaps)

<!-- -->

- [13. Cost](guide/cost.md)
  - [Monthly Estimate](guide/cost.md#monthly-estimate)
  - [Budget](guide/cost.md#budget)
  - [Main Levers](guide/cost.md#main-levers)

<!-- -->

- [14. Migration to the Environments Layout](guide/migration-to-environments.md)
  - [What Stays the Same](guide/migration-to-environments.md#what-stays-the-same)
  - [Moved Addresses](guide/migration-to-environments.md#moved-addresses)
  - [What Is Replaced](guide/migration-to-environments.md#what-is-replaced)
  - [Rollout](guide/migration-to-environments.md#rollout)
  - [Expected Downtime](guide/migration-to-environments.md#expected-downtime)
  - [Rollback](guide/migration-to-environments.md#rollback)

<!-- -->

- [15. Blue/Green Deployment (design note, not implemented)](guide/blue-green.md)
  - [Why](guide/blue-green.md#why)
  - [What changes in the service](guide/blue-green.md#what-changes-in-the-service)
  - [What changes in the CD workflow](guide/blue-green.md#what-changes-in-the-cd-workflow)
  - [Trade-offs](guide/blue-green.md#trade-offs)

# Contributing

We welcome any kind of contribution, please read the guidelines:

[CONTRIBUTING](CONTRIBUTING.md)

# The MIT License

[LICENSE](LICENSE)
