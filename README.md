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

----

# Development Setup

Before working with the Terraform infrastructure in this repository, several initial steps are required.

These steps ensure a consistent development environment and secure access to AWS resources.

---

## 1. IDE Setup (WebStorm)

If you are using **WebStorm**, it is recommended to configure automatic formatting for Terraform files.

### Install Terraform plugin

Install the official **Terraform plugin** in WebStorm to enable syntax highlighting and validation.

Steps:

- Open **Settings**
- Navigate to **Plugins**
- Search for **Terraform**
- Install the plugin

### Configure Terraform formatting watcher

To automatically format Terraform files, configure a **File Watcher**.

Steps:

1. Go to  
   `Settings → Tools → File Watchers`

2. Create a new watcher

3. Configure it as follows:

- **Name:** `terraform fmt`
- **Program:** `terraform`
- **Arguments:** `fmt`
- **File type:** Terraform

This ensures that Terraform files are automatically formatted on save.

---

## 2. Preparing AWS Access

Before running Terraform, we need to create a dedicated **AWS IAM user** that will be used to manage infrastructure.

Using a separate user is important for several reasons:

1. **Security** — the root account should never be used for infrastructure management.
2. **Auditability** — changes can be tracked per user.
3. **Access control** — permissions can be limited or revoked when needed.

### Creating the IAM user

Steps:

1. Open **AWS Console**
2. Navigate to **IAM**
3. Go to **Users**
4. Click **Create User**

Then:

- Enable **programmatic access**
- Attach permissions

For initial setup you may attach:

```shell
AdministratorAccess
```

In production environments it is recommended to replace this with a **restricted policy**.

After creating the user:

- Generate **Access Key**
- Generate **Secret Access Key**
- Copy the **User ARN**

---

## 3. Configure Local AWS Profile

Once credentials are created, configure a local AWS profile.

Run:

```bash
aws configure --profile <profile_name>
```

Enter:

- Access Key
- Secret Key
- Default region
- Output format

You can verify the configuration:

```shell
aws configure list --profile <profile_name>
```

## 4. Verify AWS Connection

Before running Terraform, verify that the AWS CLI works correctly.

Example commands:

List S3 buckets:

```shell
aws s3 ls --profile <profile_name>
```

Check current identity:

```shell
aws sts get-caller-identity --profile <profile_name>
```

If both commands work successfully, your AWS credentials are correctly configured.

## 5. Global Terraform State

In a team environment, Terraform state must not be stored locally.

If multiple engineers work on the infrastructure, local state can easily lead to inconsistencies and broken deployments.

Instead, Terraform state should be stored in a remote backend.

The most common solution in AWS environments is:

S3 bucket for storing Terraform state

This allows all team members to work with the same infrastructure state.

## 6. State Locking

When multiple engineers work with Terraform, there is a risk that two people might run terraform apply at the same time.

This can corrupt the infrastructure state and cause unpredictable results.

To prevent this, Terraform supports state locking.

In AWS environments, this is typically implemented using:

S3 — for storing state

DynamoDB — for state locking

State locking ensures that only one Terraform operation can run at a time.

## 7. Bootstrap Infrastructure

Because the Terraform backend itself requires infrastructure (S3 bucket and DynamoDB table), it is common to create a
small bootstrap Terraform project.

This bootstrap configuration is responsible for:

creating the S3 bucket for Terraform state

creating the DynamoDB table for state locking

preparing the initial infrastructure required for the main Terraform project

Once the bootstrap infrastructure is created, the main Terraform project can safely use the remote backend.


