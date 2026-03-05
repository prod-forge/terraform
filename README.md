# Prod Forge

**Prod Forge** is an open-source guide to building production-ready software systems.

The goal of this project is not to create another boilerplate or demo application.

Instead, it focuses on **everything that happens around the code** when building real products:

- architecture decisions
- team workflows
- infrastructure setup
- observability
- release engineering
- production safety

Most tutorials focus on writing the application itself.

This project focuses on **what happens before and after the code is written.**

## The idea

To demonstrate these practices, we build a **simple Todo List application**.

The application itself is intentionally simple.

However, we treat it **as if it were a real production system**, implementing modern engineering practices used in
real-world projects.

This includes:

- production-ready backend architecture
- infrastructure as code
- observability
- CI/CD pipelines
- release management
- monitoring and alerting
- rollback strategies
- security practices

The goal is to show **how to move from a simple idea to a production-ready system.**

## Project structure

This project is split into multiple repositories:

| Repository | Description |
|-------------|-------------|
| Backend | Production-ready backend application |
| Infrastructure | Terraform infrastructure for AWS |

- [Backend](https://github.com/prod-forge/backend)
- [Infrastructure](https://github.com/prod-forge/terraform)

## Overview

This repository contains the infrastructure required to run the backend system in a production-like environment.

The infrastructure is defined using **Terraform** and deployed on **AWS**.

The goal of this repository is to demonstrate how backend systems are typically deployed and operated in real production
environments.

The application itself is a simple Todo List API used as a demonstration system.

## Infrastructure components

The infrastructure includes:

- AWS ECS
- ECR
- VPC networking
- PostgreSQL
- Redis
- Load balancing
