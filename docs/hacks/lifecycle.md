# Lifecycle and dependency hacks

## ECS service ignores the task definition and the desired count

- **What:** `ignore_changes = [task_definition, desired_count]` on `aws_ecs_service.app`.
- **Where:** `infrastructure/modules/ecs-service/main.tf` (comment in the file).
- **Why:** backend CD registers a new task definition revision on every release, and Application Auto Scaling owns the task count (`guide/scaling.md`).
- **If cleaned up:** every apply rolls the service back to the revision Terraform knows (the `initial` image) and resets the task count.

## launch_type stays FARGATE

- **What:** the service sets `launch_type = "FARGATE"` instead of a capacity provider strategy.
- **Where:** `infrastructure/modules/ecs-service/main.tf` (comment in the file).
- **Why:** changing `launch_type` forces a new service; Fargate Spot is discussed in `guide/scaling.md`, "Fargate Spot trade-off".
- **If cleaned up:** switching to a capacity provider strategy replaces the service.

## RDS snapshot identifier applies only on creation

- **What:** `ignore_changes = [snapshot_identifier]` on the RDS instance.
- **Where:** `infrastructure/modules/rds/main.tf` (comment in the file).
- **Why:** the snapshot restored the first instance during the environments migration (`guide/migration-to-environments.md`); a later change of the value would replace the instance.
- **If cleaned up:** removing the ignore and changing or clearing `rds_snapshot_identifier` replaces the production database.

## create_before_destroy with name_prefix

- **What:** security groups, the VPC endpoint security group, the RDS parameter group, the ACM certificates and the imported VPN certificates use `create_before_destroy`; the groups use `name_prefix` instead of `name`.
- **Where:** `infrastructure/modules/security_groups/main.tf` (comment at the top), `infrastructure/modules/vpc/endpoints.tf`, `infrastructure/modules/monitoring/security_group/main.tf`, `infrastructure/modules/rds/parameter-group.tf`, `infrastructure/modules/acm-certificate/main.tf`, `infrastructure/modules/vpn/certificates/{server,client}/main.tf`.
- **Why:** a group or certificate in use cannot be deleted; with a unique prefix the replacement is created first and the dependents (ALB, ECS, RDS, Redis, Client VPN, listeners) switch to it before the old one is deleted.
- **If cleaned up:** a fixed `name` makes the replacement collide with the old name; without `create_before_destroy` the delete fails or hangs while the resource is attached.

## moved blocks are kept

- **What:** `infrastructure/environments/prod/moved.tf` (31 blocks from the former single root to `module.stack.*`) and a `moved` block from `aws_iam_openid_connect_provider.github` to `[0]` in `infrastructure/modules/github-oidc/main.tf`.
- **Where:** the files above; `guide/migration-to-environments.md`, "Moved Addresses".
- **Why:** they map the old addresses of live resources to the new ones; the state was already moved with `terraform state mv`, so they are no-ops that protect anyone applying an older state without the runbook.
- **If cleaned up:** an apply against a state that still has an old address destroys and recreates the resource (VPC, RDS, ECR and more).

## depends_on on outputs

- **What:** outputs that carry `depends_on`: the secret ARNs wait for their secret versions, the task execution role ARN waits for its policy attachments, the logs bucket name and domain wait for the bucket policy and ownership controls.
- **Where:** `infrastructure/modules/secrets_manager/outputs.tf`, `infrastructure/modules/iam/outputs.tf` (comment in the file), `infrastructure/modules/logs-bucket/outputs.tf`.
- **Why:** consumers must not start before the dependency exists: an ECS task with a secret ARN but no secret value, or no permission to read it, fails to start; ALB and CloudFront logging fail against a bucket without its policy or ACL settings (inference for the secrets and logs bucket outputs; no comment there).
- **If cleaned up:** the first apply of a fresh environment fails or starts tasks that crash, depending on resource order.

## depends_on between S3 bucket settings

- **What:** lifecycle configurations depend on versioning, bucket policies on the public access block, objects on the encryption configuration.
- **Where:** `infrastructure/modules/frontend/main.tf`, `infrastructure/modules/logs-bucket/main.tf`, `infrastructure/modules/observability-config/main.tf`; the NAT EIPs and NAT gateways depend on the internet gateway in `infrastructure/modules/vpc/main.tf`.
- **Why:** the AWS provider documents these orderings: a noncurrent-version rule needs versioning on, a bucket policy can be rejected while the public access block is being applied, objects uploaded before default encryption are not encrypted with the key, and an EIP for a NAT gateway needs the internet gateway (inference: no comments in the files).
- **If cleaned up:** intermittent failures on the first apply of a new environment.
