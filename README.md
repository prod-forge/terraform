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

![Architecture](https://github.com/prod-forge/terraform/blob/main/assets/architecture_diagram.png)

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

## Workflow

After the above preparation, we can begin setting up the infrastructure.

It is recommended to create the infrastructure in stages:

- ECR
- StateManager
- Github OCID
- ECS Cluster
- ALB
- ECS Service
- Task Definition

## Amazon ECR

ECR will be used as the central registry for container images built by the CI/CD pipeline.

All application images will be pushed to this registry and later pulled by the runtime environment (for example ECS,
EKS, or other compute services).

You can initialize ECR first:

```shell
terraform apply -target='module.ecr.aws_ecr_repository.prod_forge_repo'
```

### The "Chicken and Egg" Problem

![Architecture](https://github.com/prod-forge/terraform/blob/main/assets/chicken-egg-problem.png)

In many organizations, the DevOps and backend teams work independently and often in parallel. This can create a common
problem during the early stages of a project:

How can infrastructure be configured if the backend service is not yet ready for deployment?

To reduce the dependency between these teams, we introduce a simple solution: a temporary bootstrap application.

#### Initial Application Image

Inside the repository there is a folder called:

```shell
initial-image
```

This directory contains a minimal backend application used solely for bootstrapping the infrastructure.

The application should:

- use the same runtime as the real service
- be simple enough to build immediately
- be deployable to the infrastructure

For example, since the production backend uses Node.js, the bootstrap service uses Express as a minimal framework.

The goal of this service is not to implement business logic, but simply to provide a deployable container image that
allows infrastructure components to be tested.

We can build an initial image locally for initial work and upload it to ECR:

```shell
aws ecr get-login-password --region eu-central-1 \
| docker login \
--username AWS \
--password-stdin <USER_ID>.dkr.ecr.eu-central-1.amazonaws.com
```

```shell
docker buildx build \
--platform linux/amd64 \
-t <ECR_URL>:<version> \
--push .
```

##### Required Endpoints

The bootstrap service exposes a small set of endpoints.

- **/health** - This endpoint is required. When deploying services to AWS ECS, a health check must be configured. ECS
  periodically calls this endpoint to verify that the container is running correctly. The endpoint simply returns:

```shell
200 OK
```

This indicates that the service is alive and healthy.

- **/version** - This endpoint is optional but highly recommended. It returns the version of the currently running
  container. This makes it easy to:

  - verify which version is deployed
  - confirm that a deployment succeeded
  - detect situations where old containers are still running during rolling updates

## AWS Secrets Manager

Sensitive configuration values such as:

- API keys
- database credentials
- third-party service tokens
- application secrets

should never be stored in the repository or Terraform variables.

Instead, they should be stored in **AWS Secrets Manager**, which provides secure storage, access control, and auditing.

If any secrets are already known at this stage of the project, they can be added to **Secrets Manager immediately** so
that they are available for the infrastructure and application during deployment.

```shell
terraform apply -target='module.secrets_manager.aws_secretsmanager_secret.app_secret'
```

You can put some secrets:

```shell
aws secretsmanager put-secret-value \
  --secret-id prod/app/config \
  --secret-string '{"SOME_SECRET":"secret"}'
```

Now, you can get secrets:

```shell
aws secretsmanager get-secret-value \
  --secret-id prod/app/config \
  --query SecretString \
  --output text
```

```shell
aws secretsmanager get-secret-value \
  --secret-id prod/app/config \
  --query SecretString \
  --output text | jq -r '.SOME_SECRET'
```


# GitHub Integration for CI/CD

Once Secrets Manager and ECR are configured, the next step is to connect the GitHub repository to the CI/CD pipeline.

This allows the pipeline to:

- build Docker images
- push images to ECR
- trigger deployment processes automatically

## Approaches

There are two main ways to grant the CI/CD pipeline access to AWS:

### 1. Dedicated AWS User

Create a dedicated IAM user specifically for CI/CD tasks.

Then configure:

- ACCESS_KEY_ID
- SECRET_ACCESS_KEY

as GitHub Secrets in the repository settings.

All actions in the CI/CD pipeline will run under this user’s permissions.

⚠️ This approach works but requires careful management of IAM keys. Rotating secrets and enforcing least-privilege
policies can be cumbersome.

### 2. OpenID Connect (OIDC) — Recommended

A more secure and modern approach is to configure OIDC between GitHub and AWS.

- The repository itself is trusted to assume roles in AWS
- No IAM user or long-lived keys are needed
- Permissions are granted per repository, making the workflow cleaner and safer

With this setup, the GitHub Actions workflow can assume a role that has privileges such as pushing images to ECR and
deploying infrastructure.

Terraform Setup

To create the OIDC provider via Terraform, run:

```shell
terraform apply --target=module.github_oidc.aws_iam_openid_connect_provider.github
```

Terraform will output the ARN of the created resource, which must then be added to your GitHub Actions workflow for the
backend repository.

```yaml
env:
  GITHUB_ARN: <ARN>
```

This step ensures that:

- GitHub Actions can authenticate to AWS securely
- Only authorized workflows can perform deployments
- The CI/CD workflow is fully automated and auditable

Why OIDC is Recommended

- No hard-coded credentials in GitHub secrets
- Least privilege — only the repository can assume the role
- Improved security — reduces risk of compromised keys
- Cleaner workflow — easier to manage and audit access

## ECS Cluster

After applying the Terraform configuration, a new ECS Cluster should appear in the AWS Console.

You can verify this by navigating to:

```shell
AWS Console → ECS → Clusters
```

The cluster will be used to run our backend services using AWS Fargate.

## Application Load Balancer (ALB)

Once the Application Load Balancer is created, you can verify it using the AWS CLI:

```shell
aws elbv2 describe-load-balancers --region eu-central-1
```

The output should contain a DNS name for the load balancer.

Example:

```shell
DNSName: xyz123.eu-central-1.elb.amazonaws.com
```

At this stage, if you open the DNS address in your browser, the response will likely be:

```shell
503 Service Unavailable
```

This is expected because the ECS service may not yet have a healthy running task attached to the load balancer.

## ECS Service

The ECS service is responsible for running and maintaining the desired number of application tasks.

You can inspect the service using the following commands.

List services in the cluster:

```shell
aws ecs list-services \
  --cluster <CLUSTER_NAME> \
  --region eu-central-1
```

Describe the service in detail:

```shell
aws ecs describe-services \
  --cluster <CLUSTER_NAME> \
  --services <SERVICE_NAME> \
  --region eu-central-1
```

This will show information such as:

- running tasks
- desired task count
- deployment status
- load balancer configuration

## Task Definition

A Task Definition describes how our backend application should run inside ECS.

When using AWS Fargate, we define the compute resources allocated to the container.

Example configuration:

```shell
cpu    = "256"
memory = "512"
```

This defines the virtual machine resources that will be allocated to the containerized service.

The task definition also specifies the Docker image that will be deployed.
