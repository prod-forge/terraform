# Workflow

<p align="center">
  <img alt="Development Setup" src="https://github.com/prod-forge/terraform/blob/main/assets/workflow.png" width="512px" height="768px">
</p>

After the above preparation, we can begin setting up the infrastructure.

It is recommended to create the infrastructure in stages:

- ECR
- StateManager
- GitHub OIDC
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

### The "Chicken-and-Egg" Dilemma

<p align="center">
  <img alt="The Chicken and Egg Problem" src="https://github.com/prod-forge/terraform/blob/main/assets/chicken-egg-problem.png" width="512px" height="768px">
</p>

In many organizations, the DevOps and backend teams work independently and often in parallel. This can create a common
problem during the early stages of a project:

How can infrastructure be configured if the backend service is not yet ready for deployment?

To reduce the dependency between these teams, we introduce a simple solution: a temporary bootstrap application.

### Initial Application Image

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

#### Required Endpoints

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

Store secrets using the following command:

```shell
aws secretsmanager put-secret-value \
  --secret-id prod/app/config \
  --secret-string '{"SOME_SECRET":"secret"}'
```

Retrieve a secret value:

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

## GitHub Integration for CI/CD

Once Secrets Manager and ECR are configured, the next step is to connect the GitHub repository to the CI/CD pipeline.

This allows the pipeline to:

- build Docker images
- push images to ECR
- trigger deployment processes automatically

### Approaches

There are two main ways to grant the CI/CD pipeline access to AWS:

#### 1. Dedicated AWS User

Create a dedicated IAM user specifically for CI/CD tasks.

Then configure:

- ACCESS_KEY_ID
- SECRET_ACCESS_KEY

as GitHub Secrets in the repository settings.

All actions in the CI/CD pipeline will run under this user’s permissions.

This approach works but requires careful management of IAM keys. Rotating secrets and enforcing least-privilege
policies can be cumbersome.

#### 2. OpenID Connect (OIDC) - Recommended

A more secure and modern approach is to configure OIDC between GitHub and AWS.

- The repository itself is trusted to assume roles in AWS
- No IAM user or long-lived keys are needed
- Permissions are granted per repository, making the workflow cleaner and safer

With this setup, the GitHub Actions workflow can assume a role that has privileges such as pushing images to ECR and
deploying infrastructure.

### Terraform Setup

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

### Why OIDC is Recommended

- No hard-coded credentials in GitHub secrets
- Least privilege - only the repository can assume the role
- Improved security - reduces risk of compromised keys
- Cleaner workflow - easier to manage and audit access

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

You can see logs from the container:

```shell
aws logs describe-log-groups
```

Find your log group (for example, */ecs/prod-forge-todolist*):

```shell
aws logs tail <LOG_GROUP> --since 10h
```

## One-Run ECS Tasks

Certain operations should not run as permanent services.

Examples include:

- database migrations
- seed scripts
- maintenance jobs

For these cases we use one-run ECS tasks.

Inside the backend repository there is a directory:

```markdown
ecs/
```

This directory contains a task template used to run migration jobs.

These tasks are not created at the infrastructure level because they are ephemeral by nature.

Instead they are:

1. created during the release pipeline
2. executed once
3. removed after completion

This approach keeps infrastructure clean while still allowing safe execution of operational tasks.

Typical workflow:

```markdown
CI/CD → run migration task → apply schema changes → deploy new application version
```

Because database migrations follow a forward-only strategy, running them before application deployment is safe.
