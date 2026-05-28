# Terraform AWS DevOps Project Guidelines

## Important

- Write production-ready Infrastructure as Code
- Prefer small focused Terraform modules
- Add comments only when necessary
- Prefer explicit infrastructure configuration over magic defaults
- Preserve existing architecture and naming conventions
- Follow existing project patterns before introducing new ones
- Prefer extending existing modules over introducing new abstractions
- Reuse existing Terraform modules and locals before creating new ones
- Do not refactor unrelated infrastructure unless explicitly requested
- Split overly complex Terraform configurations into smaller modules
- Prefer minimal diffs
- Avoid reformatting unrelated files
- Prefer readable and maintainable infrastructure code
- Prefer simplicity over clever abstractions
- Avoid unnecessary module nesting
- Keep environments reproducible and deterministic
- All infrastructure changes must be idempotent
- Prefer immutable infrastructure patterns
- Avoid manual changes in AWS Console for managed resources
- Infrastructure state must always remain consistent

---

## Terraform Rules

- Use the latest stable Terraform version supported by the project
- Use strict version pinning for Terraform and providers
- Prefer `required_providers` and `required_version`
- Use remote state for all environments
- Never store Terraform state locally for shared environments
- Prefer explicit variable types
- Avoid `any` types
- Use `locals` to reduce duplication
- Prefer `for_each` over `count` when resource identity matters
- Avoid hardcoded values
- Use meaningful resource names
- Keep modules focused and cohesive
- Prefer data sources over duplicated resource definitions
- Avoid unnecessary dynamic blocks
- Use outputs only when required
- Prefer composition over deeply nested modules
- Keep plans predictable and readable
- Avoid resource recreation unless explicitly intended
- Always run `terraform fmt` and `terraform validate`
- Keep Terraform files logically separated:
  - `main.tf`
  - `variables.tf`
  - `outputs.tf`
  - `providers.tf`
  - `versions.tf`
  - `locals.tf`

---

## AWS Rules

- Follow AWS Well-Architected Framework principles
- Prefer managed AWS services over self-hosted solutions
- Design for high availability and fault tolerance
- Prefer multi-AZ deployments for production workloads
- Use least-privilege IAM policies
- Avoid wildcard IAM permissions unless strictly required
- Enable encryption at rest and in transit
- Use AWS KMS for sensitive resources
- Prefer IAM roles over static credentials
- Never hardcode AWS credentials or secrets
- Store secrets in:
  - AWS Secrets Manager
  - AWS Systems Manager Parameter Store
- Tag all resources consistently:
  - Environment
  - Project
  - Owner
  - ManagedBy
  - CostCenter
- Prefer private subnets for internal services
- Avoid public exposure unless required
- Use Security Groups instead of overly permissive networking
- Keep VPC architecture simple and maintainable
- Prefer Auto Scaling where applicable
- Enable CloudWatch logging and monitoring by default
- Configure alarms for critical infrastructure
- Prefer S3 lifecycle policies for cost optimization
- Enable versioning for critical S3 buckets
- Block public S3 access by default
- Use DynamoDB locking for Terraform state
- Prefer ECR over external container registries for AWS workloads
- Use ALB/NLB appropriately based on workload requirements
- Enable access logging for critical services
- Prefer Graviton instances when cost-effective and supported
- Use Infrastructure as Code for all AWS resources

---

## Terraform State Rules

- Use S3 backend for remote Terraform state
- Enable bucket versioning for state buckets
- Enable server-side encryption for state storage
- Use DynamoDB table for state locking
- Separate state files by environment and workload
- Never manually modify Terraform state files
- Never commit `.tfstate` files to version control
- Restrict access to Terraform state buckets

Example:

```hcl
terraform {
  backend "s3" {
    bucket         = "project-terraform-state"
    key            = "prod/network/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
````

---

## Module Rules

* Modules must have a single responsibility
* Keep module inputs explicit
* Avoid excessive module variables
* Provide sensible defaults only when safe
* Keep outputs minimal and intentional
* Document required inputs and outputs
* Avoid provider configuration inside reusable modules
* Prefer reusable infrastructure patterns
* Version shared modules
* Avoid circular module dependencies

Example structure:

```text
modules/
  vpc/
  ecs-service/
  rds/
  iam-role/
```

---

## Networking Rules

* Prefer dedicated VPCs per environment when appropriate
* Use private/public subnet separation
* Avoid overly permissive CIDR ranges
* Minimize inbound access
* Prefer VPC endpoints for AWS service communication
* Use NAT Gateways only when necessary due to cost
* Keep routing explicit and simple
* Enable flow logs for critical environments

---

## ECS / Kubernetes Rules

* Prefer ECS Fargate unless Kubernetes is explicitly required
* Use EKS only for workloads that benefit from Kubernetes orchestration
* Keep task/container definitions explicit
* Avoid oversized container resources
* Use health checks for all services
* Prefer rolling deployments
* Store container images in ECR
* Pin container image versions
* Avoid using `latest` tags
* Configure autoscaling policies
* Keep secrets outside container images

---

## CI/CD Rules

* All infrastructure changes must go through CI/CD
* Never apply production changes manually
* Run `terraform fmt -check`
* Run `terraform validate`
* Run `terraform plan` in CI before apply
* Require manual approval for production applies
* Store CI/CD secrets securely
* Prefer GitHub Actions, GitLab CI, or AWS CodePipeline
* Keep pipelines deterministic and reproducible
* Fail fast on validation errors
* Use separate AWS accounts/environments when possible

Example CI steps:

```yaml
- terraform fmt -check
- terraform init
- terraform validate
- terraform plan
```

---

## Security Rules

* Apply least privilege everywhere
* Never expose secrets in logs or outputs
* Rotate credentials regularly
* Enable CloudTrail in all AWS accounts
* Enable GuardDuty for production environments
* Enable AWS Config where compliance is required
* Prefer private networking
* Restrict SSH access
* Prefer SSM Session Manager over bastion hosts
* Scan Terraform code with security tools:

    * tfsec
    * checkov
    * terrascan
* Review IAM changes carefully
* Enable MFA for privileged access

---

## Monitoring & Observability Rules

* Centralize logs where possible
* Use CloudWatch dashboards for key services
* Configure actionable alarms
* Monitor:

    * CPU
    * Memory
    * Error rates
    * Latency
    * Cost anomalies
* Enable distributed tracing when applicable
* Keep retention policies explicit
* Avoid excessive logging costs

---

## Cost Optimization Rules

* Prefer cost-efficient managed services
* Right-size infrastructure resources
* Shut down non-production resources when unused
* Use autoscaling where appropriate
* Prefer Spot instances for fault-tolerant workloads
* Review unused resources regularly
* Use S3 lifecycle management
* Avoid unnecessary NAT Gateways
* Monitor AWS costs continuously
* Tag resources for cost allocation

---

## Testing Rules

* Infrastructure plans must be deterministic
* Validate all Terraform code before merge
* Keep tests readable and explicit
* Prefer automated infrastructure validation
* Test modules in isolation when possible
* Mock external dependencies only when necessary
* Use staging environments before production rollout

### Validation Commands

```bash
terraform fmt -check
terraform validate
terraform plan
```

### Optional Tooling

```bash
tflint
tfsec
checkov
terrascan
```

---

## Repository Structure Rules

Example structure:

```text
terraform/
  environments/
    dev/
    stage/
    prod/

  modules/
    vpc/
    ecs-service/
    rds/
    iam/

  global/
    state/
    networking/
```

---

## Ignore Rules

Do not analyze or modify generated/dependency files.

Ignore:

* .terraform
* .terraform.lock.hcl
* terraform.tfstate
* terraform.tfstate.backup
* crash.log
* *.tfvars
* override.tf
* override.tf.json
* *.auto.tfvars

Never commit secrets or state files.

---

## Cost Saving Rules

* Run only affected Terraform plans when possible
* Avoid full environment applies for isolated changes
* Read only relevant modules and environments
* Avoid scanning the entire repository unless necessary
* Prefer targeted validation for changed infrastructure
* Use cached providers in CI/CD when possible
* Minimize unnecessary AWS resource recreation
