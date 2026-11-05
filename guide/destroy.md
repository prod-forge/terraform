# Destroying the Infrastructure

At some point you may need to fully tear down the project — closing an environment, ending a pilot, or starting over.

Destroying infrastructure is not just running `terraform destroy`. The bootstrap layer was intentionally designed to resist accidental deletion. Understanding the order matters: destroy in the wrong sequence and you will either leave orphaned AWS resources behind, or lose Terraform state before the infrastructure is cleaned up.

## Why Order Matters

Each environment (`infrastructure/environments/dev`, `infrastructure/environments/prod`) stores its Terraform state in the S3 bucket created by the bootstrap (`bootstrap/`), under its own key.

If you destroy the bootstrap first, you lose the state file. Terraform can no longer track what infrastructure exists, and resources will be left running in AWS with no way to manage them through Terraform.

The correct order is always:

```text
1. Destroy the environments (dev first, then prod)
2. Unlock and destroy bootstrap
3. Delete the IAM user
```

## Step 1 — Destroy Infrastructure

Destroy one environment at a time from the repository root:

```shell
terraform -chdir=infrastructure/environments/dev destroy
terraform -chdir=infrastructure/environments/prod destroy
```

When dev and prod share an AWS account, destroy dev first: it reads the GitHub OIDC provider that prod owns (`create_github_oidc_provider`).

This removes all managed AWS resources:

- ECS cluster, services, and task definitions
- RDS, Redis
- VPC, subnets, security groups, load balancer
- ECR repository
- CloudFront distribution and S3 buckets (web client, assets, access logs)
- WAF web ACLs, ACM certificates and Route 53 records (when a domain is set)
- GitHub OIDC roles (and, in the environment that owns it, the OIDC provider)
- Monitoring EC2 instance
- VPN endpoint (when `enable_client_vpn = true`)

Review the plan carefully before confirming. Once applied, these resources are gone.

Some resources block a plain destroy:

- In prod the RDS instance has deletion protection (`rds_deletion_protection = true`). Set it to `false` and apply before destroying; the destroy still takes the final snapshot `<project>-<environment>-final`.
- In prod the ALB has deletion protection (`enable_deletion_protection = var.environment == "prod"`). Terraform cannot disable it during a destroy, so turn it off first: `aws elbv2 modify-load-balancer-attributes --load-balancer-arn <arn> --attributes Key=deletion_protection.enabled,Value=false` (find the ARN with `aws elbv2 describe-load-balancers --names <project>-prod-alb`).
- The web-client, assets and access-logs buckets have no `force_destroy`, and S3 refuses to delete a non-empty bucket. The web-client, assets and access-logs buckets are also versioned, so empty all object versions (S3 console "Empty", or a lifecycle run) before `terraform destroy`.
- The CloudTrail bucket `<project>-<env>-cloudtrail` (created when `enable_account_security_services = true`) is versioned, holds the audit log and has no `force_destroy`, so the destroy fails with `BucketNotEmpty`. Empty it (console "Empty", which also removes all versions and delete markers) once you are sure the audit history is no longer needed, then run the destroy again. Export the logs first if they must be kept.

Prod destroy order: set `rds_deletion_protection = false` and apply, disable ALB deletion protection, empty the five buckets (web client, assets, access logs, CloudTrail, versioned observability-config), then `terraform destroy`.

## Step 2 — Unlock the Bootstrap

The S3 bucket that stores Terraform state is protected against accidental deletion:

```hcl
lifecycle {
  prevent_destroy = true
}
```

This is intentional — it prevents the bucket from being destroyed while state files still exist inside it.

To remove this protection, open `bootstrap/main.tf` and delete the lifecycle block from the `aws_s3_bucket` resource:

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name
  # remove the lifecycle block
}
```

Then apply the change from `bootstrap/`:

```shell
terraform apply
```

This does not delete anything. It simply removes the Terraform-level guard that was blocking destruction.

The state bucket has no `force_destroy`, and it still holds the environment state files and their versions, so empty it first (S3 console "Empty", which also removes all versions and delete markers). Only do this once both environments are destroyed. Then destroy the bootstrap resources:

```shell
terraform destroy
```

This removes:

- the S3 state bucket (and all versioned state files and lock files inside it)
- the KMS key (scheduled for deletion after the 7-day window)

## Step 3 — Remove Operator Access

Operator access is managed outside of Terraform ([Development Setup](development-setup.md#preparing-aws-access)).

With IAM Identity Center (the default), remove the account assignment of the `TerraformOperator` permission set in IAM Identity Center, then delete the permission set if nothing else uses it.

Only if you used the IAM user fallback, delete that user from the AWS Console or via the CLI:

```shell
aws iam delete-access-key --user-name <USERNAME> --access-key-id <KEY_ID>
aws iam detach-user-policy --user-name <USERNAME> --policy-arn <POLICY_ARN>
aws iam delete-user --user-name <USERNAME>
```

At this point the AWS account is clean.
