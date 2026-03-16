<p align="center">
  <img alt="Logo" src="https://github.com/prod-forge/backend/blob/main/assets/prod-forge-logo.png" width="264px" height="243px">
</p>

Most tutorials teach you how to write an app. Almost none of them teach you how to **run it in production.**

**Prod Forge** is an open-source guide that covers everything around the code - the part most projects skip:
repository strategy, team workflows, CI/CD, observability, security, release management, and rollback.

To make it concrete, we build a simple Todo List API and treat it **as if real users depend on it.**

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
  - [IDE Setup (WebStorm)](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md)
    - [Install Terraform plugin](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md)
    - [Configure Terraform formatting watcher](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md)
  - [Preparing AWS Access](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md)
    - [Creating the IAM user](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md)
  - [Configure Local AWS Profile](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md)
  - [Verify AWS Connection](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md)
  - [Global Terraform State](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md)
  - [State Locking](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md)
  - [Bootstrap Infrastructure](https://github.com/prod-forge/terraform/blob/main/docs/development-setup.md)
- [2. Environments](https://github.com/prod-forge/terraform/blob/main/docs/environments.md)
  - [Environment Strategy](https://github.com/prod-forge/terraform/blob/main/docs/environments.md)
    - [Development Environment (dev)](https://github.com/prod-forge/terraform/blob/main/docs/environments.md)
    - [Production Environment (prod)](https://github.com/prod-forge/terraform/blob/main/docs/environments.md)
    - [Why Not Use Pre-Production?](https://github.com/prod-forge/terraform/blob/main/docs/environments.md)
  - [Key Principle](https://github.com/prod-forge/terraform/blob/main/docs/environments.md)
- [3. Workflow](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
  - [Amazon ECR](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
    - [The "Chicken-and-Egg" Dilemma](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
      - [Initial Application Image](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
        - [Required Endpoints](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
  - [AWS Secrets Manager](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
  - [GitHub Integration for CI/CD](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
    - [Approaches](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
      - [1. Dedicated AWS User](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
      - [2. OpenID Connect (OIDC) — Recommended](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
  - [ECS Cluster](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
  - [Application Load Balancer (ALB)](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
  - [ECS Service](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
  - [Task Definition](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
  - [One-Run ECS Tasks](https://github.com/prod-forge/terraform/blob/main/docs/workflow.md)
- [4. Observability](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
  - [Deployment Model](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
  - [Why EC2?](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
  - [Observability Data Flow](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
  - [Advantages of This Approach](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
    - [Simplicity](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
    - [Cost Efficiency](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
    - [Full Control](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
    - [Infrastructure Independence](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
  - [Limitations](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
    - [Single Point of Failure](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
    - [Scaling Limitations](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
    - [Operational Maintenance](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
  - [When to Use Managed Observability](https://github.com/prod-forge/terraform/blob/main/docs/observability.md)
- [5. Debugging and Troubleshooting](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
  - [ECS / Fargate Debugging](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
    - [Inspect ECS Tasks](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
    - [Execute Commands Inside Container](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
  - [RDS, Redis Debugging (OpenVPN)](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
    - [Install OpenVPN](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
    - [Generate Certificates](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
    - [Generate Client Certificate](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
    - [Generate VPN Client Configuration](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
    - [Verify VPN Connection](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
    - [Connect to RDS or Redis](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
  - [EC2 SSH Connection](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
    - [SSH Setup](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
    - [Debugging bootstrap.sh](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md)
- [6. Troubleshooting](https://github.com/prod-forge/terraform/blob/main/docs/troubleshooting.md)
  - [EC2/ECS + RDS Network Routing Connection](https://github.com/prod-forge/terraform/blob/main/docs/troubleshooting.md)

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
