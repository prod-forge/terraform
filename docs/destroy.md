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
- In prod the ALB has deletion protection. Disable it first: `aws elbv2 modify-load-balancer-attributes --load-balancer-arn <arn> --attributes Key=deletion_protection.enabled,Value=false`.
- The web-client, assets and access-logs buckets are versioned and S3 refuses to delete a non-empty bucket. Empty all object versions (S3 console "Empty", or a lifecycle run) before `terraform destroy`.

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

Now destroy the bootstrap resources:

```shell
terraform destroy
```

This removes:

- the S3 state bucket (and all versioned state files and lock files inside it)
- the KMS key

## Step 3 — Delete the IAM User

The IAM user created during initial setup is managed outside of Terraform (it was created manually to bootstrap access). Delete it from the AWS Console or via the CLI:

```shell
aws iam delete-access-key --user-name <USERNAME> --access-key-id <KEY_ID>
aws iam detach-user-policy --user-name <USERNAME> --policy-arn <POLICY_ARN>
aws iam delete-user --user-name <USERNAME>
```

At this point the AWS account is clean.
