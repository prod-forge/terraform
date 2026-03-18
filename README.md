<p align="center">
  <img alt="Logo" src="https://github.com/prod-forge/backend/blob/main/assets/prod-forge-logo.png" width="264px" height="243px">
</p>

AI made writing backend code easy but running it in production is still hard.

**Prod Forge** is an open-source reference that focuses on everything beyond the code:
CI/CD, infrastructure, observability, deployment, migrations, and rollback.

A simple Todo API, built as if it were a real production system.

---

## Project structure

| Repository                                                | Description                 |
| --------------------------------------------------------- | --------------------------- |
| [Backend](https://github.com/prod-forge/backend)          | NestJS API - the main guide |
| [Infrastructure](https://github.com/prod-forge/terraform) | Terraform on AWS            |

## Stack

<p align="center">
  <img alt="Architecture" src="https://github.com/prod-forge/backend/blob/main/assets/architecture_diagram.png">
</p>

| Layer          | Tools                                          |
| -------------- |------------------------------------------------|
| Backend        | NestJS · Prisma · PostgreSQL · Redis · Docker  |
| Infrastructure | AWS · ECR · ECS · RDS · ElasticCache           |
| Observability  | Prometheus · Grafana · Loki · Promtail         |
| Quality        | ESLint · Prettier · Husky · Commitlint · CI/CD |

# Table of contents

- [1. Development Setup](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md)
  - [IDE Setup (WebStorm)](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md#ide-setup-webstorm)
    - [Install Terraform plugin](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md#install-terraform-plugin)
    - [Configure Terraform formatting watcher](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md#configure-terraform-formatting-watcher)
  - [Preparing AWS Access](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md#preparing-aws-access)
    - [Creating the IAM user](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md#creating-the-iam-user)
  - [Configure Local AWS Profile](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md#configure-local-aws-profile)
  - [Verify AWS Connection](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md#verify-aws-connection)
  - [Global Terraform State](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md#global-terraform-state)
  - [State Locking](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md#state-locking)
  - [Bootstrap Infrastructure](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md#bootstrap-infrastructure)

<!-- -->

- [2. Environments](https://github.com/prod-forge/terraform/blob/main/docs/environments.md)
  - [Environment Strategy](https://github.com/prod-forge/terraform/blob/main/docs/environments.md#environment-strategy)
    - [Development Environment (dev)](https://github.com/prod-forge/terraform/blob/main/docs/environments.md#development-environment-dev)
    - [Production Environment (prod)](https://github.com/prod-forge/terraform/blob/main/docs/environments.md#production-environment-prod)
    - [Why Not Use Pre-Production?](https://github.com/prod-forge/terraform/blob/main/docs/environments.md#why-not-use-pre-production)
  - [Key Principle](https://github.com/prod-forge/terraform/blob/main/docs/environments.md#key-principle)

<!-- -->

- [3. Workflow](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
  - [Amazon ECR](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#amazon-ecr)
    - [The "Chicken-and-Egg" Dilemma](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#the-chicken-and-egg-dilemma)
    - [Initial Application Image](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#initial-application-image)
      - [Required Endpoints](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#required-endpoints)
  - [AWS Secrets Manager](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#aws-secrets-manager)
  - [GitHub Integration for CI/CD](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#github-integration-for-cicd)
    - [Approaches](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#approaches)
      - [1. Dedicated AWS User](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#1-dedicated-aws-user)
      - [2. OpenID Connect (OIDC) - Recommended](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#2-openid-connect-oidc--recommended)
    - [Terraform Setup](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#terraform-setup)
    - [Why OIDC is Recommended](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#why-oidc-is-recommended)
  - [ECS Cluster](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#ecs-cluster)
  - [Application Load Balancer (ALB)](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#application-load-balancer-alb)
  - [ECS Service](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#ecs-service)
  - [Task Definition](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#task-definition)
  - [One-Run ECS Tasks](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md#one-run-ecs-tasks)

<!-- -->

- [4. Observability](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
  - [Deployment Model](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#deployment-model)
  - [Why EC2?](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#why-ec2)
  - [Observability Data Flow](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#observability-data-flow)
  - [Advantages of This Approach](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#advantages-of-this-approach)
    - [Simplicity](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#simplicity)
    - [Cost Efficiency](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#cost-efficiency)
    - [Full Control](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#full-control)
    - [Infrastructure Independence](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#infrastructure-independence)
  - [Limitations](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#limitations)
    - [Single Point of Failure](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#single-point-of-failure)
    - [Scaling Limitations](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#scaling-limitations)
    - [Operational Maintenance](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#operational-maintenance)
  - [When to Use Managed Observability](https://github.com/prod-forge/terraform/blob/main/docs/observability.md#when-to-use-managed-observability)

<!-- -->

- [5. Debugging](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
  - [ECS / Fargate Debugging](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#ecs--fargate-debugging)
    - [Inspect ECS Tasks](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#inspect-ecs-tasks)
    - [Execute Commands Inside Container](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#execute-commands-inside-container)
  - [RDS, Redis Debugging (OpenVPN)](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#rds-redis-debugging-openvpn)
    - [Install OpenVPN](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#install-openvpn)
    - [Generate Certificates](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#generate-certificates)
    - [Generate Client Certificate](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#generate-client-certificate)
    - [Generate VPN Client Configuration](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#generate-vpn-client-configuration)
    - [Verify VPN Connection](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#verify-vpn-connection)
    - [Connect to RDS or Redis](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#connect-to-rds-or-redis)
  - [EC2 SSH Connection](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#ec2-ssh-connection)
    - [SSH Setup](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#ssh-setup)
    - [Debugging bootstrap.sh](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md#debugging-bootstrapsh)

<!-- -->

- [6. Troubleshooting](https://github.com/prod-forge/terraform/blob/main/docs/troubleshooting.md)
  - [EC2/ECS + RDS Network Routing Connection](https://github.com/prod-forge/terraform/blob/main/docs/troubleshooting.md#ec2ecs--rds-network-routing-connection)

# Conclusion

Building software is not just about writing code.

Most engineers learn the craft of coding early in their careers. But the gap between writing working code and running a
reliable system in production is wide - and rarely documented in one place.

This project is an attempt to close that gap.

Not by providing a magic template you can clone and ship. But by walking through every decision that happens before,
during, and after the code is written.

The stack used here - NestJS, Postgres, Redis, Terraform, AWS - is not the point. These are just tools. The principles
behind them apply to almost any production backend, regardless of language or cloud provider.

What matters is the thinking:

- Why does repository structure affect team velocity?
- Why does commit discipline make releases safer?
- Why does observability matter before something breaks?
- Why does a rollback plan need to exist before you need it?

These are not advanced topics. They are basic requirements for any system that real users depend on.
The goal of Prod Forge is to make these practices visible, understandable, and reusable.

## What comes next

This project is actively evolving.
Planned additions include:

- Frontend repository with the same level of production treatment
- Mobile App repository with the same level of production treatment
- Kubernetes-based infrastructure as an alternative to ECS

If there is something missing that you would find valuable, open an issue or start a discussion.

## A final thought

The best time to set up these practices is at the beginning of a project.

The second best time is now.

A system without observability is a system you cannot debug under pressure. A team without a defined workflow is a team
that slows down as it grows. A deployment without a rollback plan is a deployment that will eventually cause an incident
with no recovery path.

None of these things are difficult to set up. They are just easy to skip.
This project exists as a reminder not to skip them.

# Contributing

We welcome any kind of contribution, please read the guidelines:

[CONTRIBUTING](https://github.com/prod-forge/terraform/blob/main/CONTRIBUTING.md)

# The MIT License

[LICENSE](https://github.com/prod-forge/terraform/blob/main/LICENSE.md)
