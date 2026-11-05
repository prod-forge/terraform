# AWS hacks

## Logs bucket without a CMK and with ACLs

- **What:** the ALB and CloudFront access logs bucket uses SSE-S3 and object ownership with ACLs, not a KMS key and not `BucketOwnerEnforced`.
- **Where:** `infrastructure/modules/logs-bucket/main.tf` (comment in the file).
- **Why:** ALB access logs support only SSE-S3, and CloudFront standard logging needs ACLs enabled.
- **If cleaned up:** switching to a CMK or `BucketOwnerEnforced` silently stops ALB or CloudFront log delivery.

## ECR keeps the initial image

- **What:** the ECR lifecycle policy has a first rule that "expires" images tagged `initial` only above 9999 images, before the "keep last 3 images" rule.
- **Where:** `infrastructure/modules/ecr/main.tf`; the `image_tag` default `"initial"` in `infrastructure/modules/task_definition/variables.tf`.
- **Why:** the task definition Terraform creates points at the `initial` placeholder image (`initial-image/`, `guide/workflow.md`, "The 'Chicken-and-Egg' Dilemma"); the image must survive the cleanup of old releases.
- **If cleaned up:** without the rule the `initial` image is expired after three releases, and a fresh service or a task definition rebuilt by Terraform cannot pull its image.

## ECR encryption type is fixed

- **What:** the repository sets `encryption_type = "KMS"`.
- **Where:** `infrastructure/modules/ecr/main.tf` (comment in the file).
- **Why:** changing the encryption type forces a new repository (`guide/workflow.md`).
- **If cleaned up:** a new repository without the released images.

## CloudTrail ARN built from parts

- **What:** the trail ARN is assembled from the region, account and trail name in a local instead of referencing `aws_cloudtrail.this.arn`.
- **Where:** `infrastructure/modules/security-baseline/main.tf` (comment in the file).
- **Why:** the KMS key, bucket and SNS topic policies need the trail ARN and must exist before the trail is created.
- **If cleaned up:** a dependency cycle between the trail and its policies.

## One GitHub OIDC provider per account

- **What:** `create_oidc_provider` creates the provider in one environment and reads it with a data source in the other; no `thumbprint_list` is set.
- **Where:** `infrastructure/modules/github-oidc/main.tf` (comment in the file); `create_github_oidc_provider` in `infrastructure/environments/<env>/terraform.tfvars` (prod creates it).
- **Why:** only one provider per URL may exist in an account; AWS validates the GitHub certificate chain itself and ignores thumbprints for `token.actions.githubusercontent.com`. The account security services (CloudTrail, GuardDuty, Access Analyzer) are skipped in dev for the same shared-account reason.
- **If cleaned up:** creating the provider in both environments fails with "already exists"; destroying prod before dev breaks dev's roles (`guide/destroy.md`).

## Missing VPN key files resolve to an empty string

- **What:** the environment roots read the Client VPN PEM files with `fileexists(...) ? file(...) : ""`; a `validation` on `enable_client_vpn` fails the plan when the VPN is enabled without them.
- **Where:** `infrastructure/environments/<env>/main.tf` (comment in the file), `infrastructure/environments/<env>/variables.tf`.
- **Why:** the key files are git-ignored, and `validate`, CI and `terraform test` must work in a fresh clone.
- **If cleaned up:** a plain `file()` breaks `validate` and CI; dropping the validation lets an apply try to import empty certificates.

## CloudFront Function strips the /assets prefix

- **What:** a viewer-request CloudFront Function on the `/assets/*` behavior removes `/assets` from the URI before the request reaches the assets bucket.
- **Where:** `infrastructure/modules/frontend/main.tf` (`aws_cloudfront_function.assets_path`); asserted in `infrastructure/environments/prod/tests/edge.tftest.hcl`.
- **Why:** frontend CD (`frontend/.github/workflows/cd.yml`) syncs `assets/` to the bucket root, while the web client requests `<cloudfront_url>/assets/<file>`. Without the function every asset request misses, S3 answers 403, and the SPA error response turns it into `index.html` with status 200.
- **If cleaned up:** every asset URL returns HTML with 200 again. If frontend CD is changed to upload under an `assets/` prefix, the function must go in the same change, or requests reach `<file>` at the root and miss.
