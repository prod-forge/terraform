# Migration to the Environments Layout

The single `infrastructure/` root is now `infrastructure/environments/prod` (and a new `infrastructure/environments/dev`), both calling `infrastructure/modules/stack`. This page is the runbook for moving the live prod, which was built from the old root on `main`, to this layout and to every change made in the same phase (private networking, encryption, per-environment names).

Read it end to end before the maintenance window. Nothing here has been applied by CI: run `terraform plan` yourself at each step and stop if the plan shows a replacement that is not listed below.

## What Stays the Same

- **State.** `infrastructure/environments/prod` uses the same backend as the old root: bucket `prod-forge-todolist-terraform-state-prod`, key `infrastructure/terraform.tfstate`, `use_lockfile = true`. `terraform init` finds the existing state; no `-migrate-state` is needed. Dev gets its own key, `environments/dev/terraform.tfstate`.
- **Addresses.** `infrastructure/environments/prod/moved.tf` moves every old address under `module.stack`, so the move alone recreates nothing (`terraform plan` prints `has moved to` for each resource). Terraform refuses a `-target` apply while `moved` blocks are still pending, and this rollout needs targeted applies, so step 2 applies the same moves with `terraform state mv` first; the `moved` blocks are then no-ops that protect anyone who applies without the runbook.
- **The application secret** `prod_forge/backend/config-v1`, its KMS key, the VPC, its subnets and route tables, the Client VPN endpoint and the CloudFront distribution (and its `*.cloudfront.net` domain) are updated in place.

## Moved Addresses

`moved.tf` (prod only):

| From | To |
| --- | --- |
| `module.<name>` for `ecr`, `github_oidc`, `secrets_manager`, `vpc`, `iam`, `security_groups`, `load_balancer`, `logs_bucket`, `api_certificate`, `cloudfront_certificate`, `dns`, `ecs_cluster`, `ecs_service`, `service_discovery`, `task_definition`, `rds`, `redis`, `observability_config`, `monitoring_iam`, `monitoring_sg`, `monitoring_ec2`, `alarms`, `frontend` | `module.stack.module.<name>` |
| `module.<name>` for `waf_alb`, `waf_cloudfront` (now `enable_waf`) and `server_vpn_certificate`, `client_vpn_certificate`, `vpn_endpoint`, `vpn_association`, `vpn_rules` (now `enable_client_vpn`) | `module.stack.module.<name>[0]` |
| `aws_vpc_security_group_ingress_rule.ecs_from_monitoring` | `module.stack.aws_vpc_security_group_ingress_rule.ecs_from_monitoring` |

Inside the modules:

| Module | From | To |
| --- | --- | --- |
| `github-oidc` | `aws_iam_openid_connect_provider.github` | `aws_iam_openid_connect_provider.github[0]` (now `create_oidc_provider`) |
| `iam` | `aws_iam_policy.allow_rds_secret` | `aws_iam_policy.secrets_read` (the name still changes, so it is replaced) |
| `monitoring/iam` | `aws_iam_role_policy.observability_config[0]` | `aws_iam_role_policy.observability_config` |
| `vpc` | `aws_route_table.private` | `aws_route_table.private[0]` |

Modules that did not exist on `main` (WAF, logs bucket, certificates, DNS, alarms, Cloud Map, observability config) have nothing in the state, so their `moved` blocks are no-ops and the resources are created.

## What Is Replaced

A `moved` block fixes an address, not a name. Every resource whose name, identifier or a force-new argument changed is destroyed and created again. Grouped in the order the rollout below handles them:

| Order | Resource (new address under `module.stack`) | Why | Data impact |
| --- | --- | --- | --- |
| 1 | `module.vpc`: NAT gateways, EIPs, private route tables 1, routes, S3 and interface endpoints, flow logs | New (private networking) | none |
| 2 | `module.ecr.aws_ecr_repository.prod_forge_repo` and its lifecycle policy | KMS encryption and the name `<project>` -> `<project>-prod` | images: copied by hand (step 5) |
| 2 | `module.frontend.aws_s3_bucket.web_client`, `.assets` with their public access blocks and policies | Bucket names `<project>-web-client` -> `<project>-prod-web-client` (same for assets) | objects: copied by hand (step 5) |
| 3 | `module.security_groups`: `alb_sg`, `ecs_sg`, `rds_sg`, `redis_sg`, `vpn_sg` | Name prefix `<project>-prod-...`, descriptions, restricted egress. `create_before_destroy`: new groups first | none |
| 3 | `module.monitoring_sg.aws_security_group.monitoring` | `monitoring-sg` -> `<project>-prod-monitoring-sg-*`. `create_before_destroy` | none |
| 3 | `module.vpc.aws_security_group.vpc_endpoints` | New, `name_prefix` | none |
| 4 | `module.iam`: `ecs-task-execution-role`, `ecs-task-role`, `allow-rds-secret-access` and attachments | Names `<project>-prod-ecs-task-execution-role`, `<project>-prod-ecs-task-role`, `<project>-prod-ecs-secrets-read` | none |
| 4 | `module.monitoring_iam`: `ec2-ecr-role`, `ec2-secrets-access`, `ec2-instance-profile`; `aws_iam_policy_attachment.ec2_ecr_policy` -> `aws_iam_role_policy_attachment.ecr_read` | Names `<project>-prod-monitoring-*`. The old exclusive attachment would detach the managed policy from other environments' roles | none |
| 4 | `module.github_oidc.aws_iam_role.github_actions` -> `aws_iam_role.github["backend"]`, `["frontend"]`; `github-actions-*` policies in `ecr`, `ecs_service`, `frontend` | One role per repository; names `<project>-prod-github-*` | CD must use the new role names |
| 5 | `module.rds.aws_db_instance.postgres` (`prod-forge-database` -> `prod-forge-todolist-prod-postgres`), `module.vpc.aws_db_subnet_group.main` (`main-db-subnet-group` -> `<project>-prod-db-subnet-group`) | Identifier, storage encryption, KMS key (all force new) | restored from an encrypted snapshot (steps 4 and 6) |
| 5 | `module.redis`: `aws_elasticache_cluster.redis` -> `aws_elasticache_replication_group.redis`, subnet group | Replication group with failover, TLS, AUTH, KMS; names `<project>-prod-redis*` | cache content lost |
| 6 | `module.load_balancer`: `aws_lb.app`, `aws_lb_target_group.app`, `aws_lb_listener.app` | Names `<project>-prod-alb`, `<project>-prod-tg` | new ALB DNS name |
| 6 | `module.ecs_cluster.aws_ecs_cluster.app`, `module.ecs_service.aws_ecs_service.app`, autoscaling policies | Names `<project>-prod-cluster`, `<project>-prod-service`, `<project>-prod-*-target-tracking` | none |
| 6 | `module.task_definition`: `aws_ecs_task_definition.app`, log groups `/ecs/<project>` and `/ecs/<project>-task-migration` | Family `<project>-prod-task`, log groups `/ecs/<project>-prod*` | old log groups kept (step 4) |
| 7 | `module.monitoring_ec2.aws_instance.monitoring` | No key pair, new bootstrap (`user_data_replace_on_change`) | Prometheus, Loki and Grafana data on the old root volume |
| 7 | `module.monitoring_ssh` key pair | Removed (SSM only) | none |
| 7 | Generated secrets `<project>/prod/redis-auth`, `jwt-secret`, `grafana-admin`, WAF ACLs, certificates and DNS (with a domain), logs bucket, alarms, SNS, budget, Cloud Map, observability config bucket | New | none |
| 7 | `module.security_baseline`: CloudTrail trail, its bucket, KMS key and SNS topic, GuardDuty detector, IAM Access Analyzer | New. If the account already has a GuardDuty detector in the region, import it first: `terraform import 'module.stack.module.security_baseline.aws_guardduty_detector.this[0]' <detector-id>`. If an account analyzer already exists, import it too: `terraform import 'module.stack.module.security_baseline.aws_accessanalyzer_analyzer.this[0]' <analyzer-name>` | none |

Updated in place: the VPC and subnets (`Name` tags, the AZs stay `eu-central-1a`/`eu-central-1b`), the internet gateway, the public route table, the OIDC provider (thumbprints dropped), the secrets KMS key (rotation on, description), `prod_forge/backend/config-v1` (recovery window), the Client VPN endpoint (description, security group), its certificates (tags) and association, the CloudFront distribution (new origins, WAF, logging), the OACs (names), and the tags of every resource that gains `CostCenter` and `Repository` from `default_tags`.

The notes from earlier tasks about the ECS security group moving from inline to standalone rules and about `service_registries` being an in-place update no longer apply: the ECS service and its security group are replaced by the rename, so both are created fresh.

Without `-target`, Terraform would destroy the old RDS instance with the `skip_final_snapshot = true` stored in the state (no final snapshot), fail on the non-empty ECR repository and buckets, and start the new service while NAT routes are still being created. The steps below avoid all three.

Destroying the old RDS instance also deletes its automated backups, so the point-in-time restore history is lost. Only the manual snapshot `prod-forge-migration` (and its encrypted copy) remains; the new instance builds its own backup history from the restore onward.

## Rollout

Plan a maintenance window of about one hour and 15 minutes. Freeze backend and frontend deploys for its duration.

### 1. Bootstrap: drop the DynamoDB lock table

None of the roots uses `dynamodb_table`; locking is the S3 lock file. Remove the unused table:

```shell
terraform -chdir=bootstrap plan    # expect: destroy aws_dynamodb_table.terraform_locks, update tags in place
terraform -chdir=bootstrap apply
```

The bootstrap state is local (`bootstrap/terraform.tfstate` on the machine that created it). If that file is lost, delete the table with `aws dynamodb delete-table --table-name prod-forge-todolist-terraform-locks-prod` instead. Its point-in-time backups go with it; they only ever held lock entries.

### 2. Initialize the prod root and apply the moves

```shell
terraform -chdir=infrastructure/environments/prod init
terraform -chdir=infrastructure/environments/prod plan
```

The VPN key files are still read from `infrastructure/vpn-key/` (`vpn_key_dir = "../../vpn-key"`); the plan fails with an `enable_client_vpn` validation error if they are missing. Check the plan against the tables above: every old address appears as `has moved to`, and every replacement is listed. Do not apply it.

Keep a copy of the current state outside the repository (the state bucket is versioned too), then apply the moves from `moved.tf` to the state. `state mv` only rewrites the state; it calls no AWS API:

```shell
cd infrastructure/environments/prod
terraform state pull > ~/prod-forge-state-before-migration.json   # contains secrets: delete it in step 9

in_state() { terraform state list | awk -v a="$1" 'index($0, a ".") == 1 || index($0, a "[") == 1 || $0 == a { f = 1 } END { exit !f }'; }
mv_if_present() { if in_state "$1"; then terraform state mv "$1" "$2"; fi; }

for m in ecr github_oidc secrets_manager vpc iam security_groups load_balancer logs_bucket \
         api_certificate cloudfront_certificate dns ecs_cluster ecs_service service_discovery \
         task_definition rds redis observability_config monitoring_iam monitoring_sg monitoring_ec2 \
         alarms frontend; do
  mv_if_present "module.$m" "module.stack.module.$m"
done
for m in waf_alb waf_cloudfront server_vpn_certificate client_vpn_certificate vpn_endpoint \
         vpn_association vpn_rules; do
  mv_if_present "module.$m" "module.stack.module.$m[0]"
done
mv_if_present aws_vpc_security_group_ingress_rule.ecs_from_monitoring \
  module.stack.aws_vpc_security_group_ingress_rule.ecs_from_monitoring

# Moves inside the modules
mv_if_present module.stack.module.vpc.aws_route_table.private 'module.stack.module.vpc.aws_route_table.private[0]'
mv_if_present module.stack.module.github_oidc.aws_iam_openid_connect_provider.github \
  'module.stack.module.github_oidc.aws_iam_openid_connect_provider.github[0]'
mv_if_present module.stack.module.iam.aws_iam_policy.allow_rds_secret module.stack.module.iam.aws_iam_policy.secrets_read
cd -

terraform -chdir=infrastructure/environments/prod plan   # no "has moved to" lines left; same replacements as before
```

`module.monitoring_ssh` stays where it is: it has no configuration any more and is destroyed in step 6.

### 3. Network first

Create NAT, private routes and endpoints before any task runs in the private subnets:

```shell
terraform -chdir=infrastructure/environments/prod apply \
  -target=module.stack.module.vpc.aws_route.private_nat \
  -target=module.stack.module.vpc.aws_vpc_endpoint.s3 \
  -target=module.stack.module.vpc.aws_vpc_endpoint.interface \
  -target=module.stack.module.vpc.aws_flow_log.this
```

Do not target the whole `module.vpc`: that would replace the DB subnet group while the old RDS instance still uses it.

### 4. Keep the data-bearing resources out of Terraform's way

Stop the application so the snapshot is consistent, then take it:

```shell
aws ecs update-service --cluster prod-forge-todolist-cluster --service prod-forge-todolist-service --desired-count 0
aws ecs wait services-stable --cluster prod-forge-todolist-cluster --services prod-forge-todolist-service

aws rds create-db-snapshot --db-instance-identifier prod-forge-database --db-snapshot-identifier prod-forge-migration
aws rds wait db-snapshot-available --db-snapshot-identifier prod-forge-migration

# The old instance is unencrypted; an encrypted copy is needed to restore into an encrypted instance.
KMS_ARN=$(terraform -chdir=infrastructure/environments/prod state show -no-color 'module.stack.module.secrets_manager.aws_kms_key.this' | awk -F'"' '/^ *arn /{print $2}')
aws rds copy-db-snapshot --source-db-snapshot-identifier prod-forge-migration \
  --target-db-snapshot-identifier prod-forge-migration-encrypted --kms-key-id "$KMS_ARN"
aws rds wait db-snapshot-available --db-snapshot-identifier prod-forge-migration-encrypted
```

Remove the old ECR repository, the web client and assets buckets and the ECS log groups from the state, so Terraform creates the new ones next to them instead of trying to delete them (it cannot delete a non-empty repository or bucket, and deleting a log group deletes its history):

```shell
terraform -chdir=infrastructure/environments/prod state rm \
  'module.stack.module.ecr.aws_ecr_repository.prod_forge_repo' \
  'module.stack.module.ecr.aws_ecr_lifecycle_policy.prod_forge_repo_policy' \
  'module.stack.module.frontend.aws_s3_bucket.web_client' \
  'module.stack.module.frontend.aws_s3_bucket_public_access_block.web_client' \
  'module.stack.module.frontend.aws_s3_bucket_policy.web_client' \
  'module.stack.module.frontend.aws_s3_bucket.assets' \
  'module.stack.module.frontend.aws_s3_bucket_public_access_block.assets' \
  'module.stack.module.frontend.aws_s3_bucket_policy.assets' \
  'module.stack.module.task_definition.aws_cloudwatch_log_group.ecs' \
  'module.stack.module.task_definition.aws_cloudwatch_log_group.ecs_migration'
```

The old resources keep running untouched: the old buckets keep their policy for the current distribution until step 6 switches the origins.

### 5. Create the new repository and buckets, copy the data

```shell
terraform -chdir=infrastructure/environments/prod apply \
  -target=module.stack.module.ecr.aws_ecr_repository.prod_forge_repo \
  -target=module.stack.module.frontend.aws_s3_bucket_public_access_block.web_client \
  -target=module.stack.module.frontend.aws_s3_bucket_public_access_block.assets

aws s3 sync s3://prod-forge-todolist-web-client s3://prod-forge-todolist-prod-web-client
aws s3 sync s3://prod-forge-todolist-assets s3://prod-forge-todolist-prod-assets
```

Copy the images the service and rollbacks need (the running release and `initial`) into `prod-forge-todolist-prod`. Log Docker in to the registry first (the old and the new repository share the account's registry):

```shell
REGISTRY=$(terraform -chdir=infrastructure/environments/prod output -raw ecr_repository_url | cut -d/ -f1)
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin "$REGISTRY"

NEW=$(terraform -chdir=infrastructure/environments/prod output -raw ecr_repository_url)
OLD=${NEW%-prod}
for tag in initial <release-tag>; do
  docker pull --platform linux/amd64 "$OLD:$tag"
  docker tag "$OLD:$tag" "$NEW:$tag"
  docker push "$NEW:$tag"
done
```

### 6. Apply the rest

Restore the database from the encrypted copy on creation:

```shell
PLAN_DIR="$(mktemp -d)"   # plan files contain secrets: keep them outside the repository
terraform -chdir=infrastructure/environments/prod plan -var=rds_snapshot_identifier=prod-forge-migration-encrypted \
  -var=image_tag=<release-tag> -out="$PLAN_DIR/migration.plan"
terraform -chdir=infrastructure/environments/prod apply "$PLAN_DIR/migration.plan"
rm -rf "$PLAN_DIR"
```

`image_tag` must be the release tag copied in step 5: the task definition is created once with it, and `ignore_changes = [task_definition]` on the service keeps later applies from replacing it, so the default `initial` image would keep running until the next deploy.

The plan must match the replacement table. Terraform orders the rest itself: new security groups and IAM roles first, then the old ECS service and ALB are deleted, RDS and Redis are recreated, and the new ALB, target group, listener, task definition and service are created. `rds_snapshot_identifier` is only read when the instance is created (`ignore_changes`), so it does not need to stay in `terraform.tfvars`.

### 7. Verify

```shell
aws ecs describe-services --cluster prod-forge-todolist-prod-cluster --services prod-forge-todolist-prod-service \
  --query 'services[0].[runningCount,desiredCount,deployments[0].rolloutState]'
terraform -chdir=infrastructure/environments/prod output api_url
curl -fsS "$(terraform -chdir=infrastructure/environments/prod output -raw api_url)/health"
```

- `runningCount` must reach 2. If the service settled at fewer tasks, run `aws ecs update-service --cluster prod-forge-todolist-prod-cluster --service prod-forge-todolist-prod-service --desired-count 2`; Application Auto Scaling keeps the minimum at 2 from then on.
- The running task must use the release image, not `initial`:

  ```shell
  TASK_DEF="$(aws ecs describe-services --cluster prod-forge-todolist-prod-cluster --services prod-forge-todolist-prod-service \
    --query 'services[0].taskDefinition' --output text)"
  aws ecs describe-task-definition --task-definition "$TASK_DEF" --query 'taskDefinition.containerDefinitions[0].image'
  ```

  The tag must be `<release-tag>`. If it shows `initial`, the apply ran without `-var=image_tag=<release-tag>`: re-run the CD deploy of the release to replace the task definition.
- The old security groups are deleted once the network interfaces of the old tasks are released. If the apply waits on `DependencyViolation` for a few minutes, that is the ENI release; it finishes on its own.
- The new Redis is empty; the application rebuilds the cache on demand.
- Confirm the SNS email subscription for `alert_email`.

### 8. Point the pipelines at the new names

The workflows read every name from GitHub variables; set them from `terraform output` as listed in [Deploy workflow variables](workflow.md#deploy-workflow-variables).

| Repository | Change |
| --- | --- |
| backend `cd.yml`, `rollback.yml`, `show-ecs-revisions.yml` | `AWS_DEPLOY_ROLE_ARN` = `github_backend_role_arn` (`<project>-prod-github-backend-role`); `ECR_REPOSITORY` `prod-forge-todolist-prod`; `ECS_CLUSTER` `prod-forge-todolist-prod-cluster`; `ECS_SERVICE` `prod-forge-todolist-prod-service`; `ECS_TASK_FAMILY` `prod-forge-todolist-prod-task` |
| backend migration task (`cd.yml`) | `ECS_MIGRATION_TASK_FAMILY` `prod-forge-todolist-prod-migration-task` (the only migration family the deploy role may run), `ECS_MIGRATION_LOG_GROUP` `/ecs/prod-forge-todolist-prod-task-migration`, `PRIVATE_SUBNET_IDS`, `ECS_SECURITY_GROUP_ID`; the run uses `assignPublicIp=DISABLED` |
| frontend `cd.yml`, `rollback.yml`, `show-web-client-versions.yml` | `AWS_DEPLOY_ROLE_ARN` = `github_frontend_role_arn` (`<project>-prod-github-frontend-role`); `S3_WEB_CLIENT_BUCKET` `prod-forge-todolist-prod-web-client`; `S3_ASSETS_BUCKET` `prod-forge-todolist-prod-assets`; `CLOUDFRONT_DISTRIBUTION_ID`; without a domain, set `VITE_API_BASE_URL` from the new `api_url` and rebuild (the ALB DNS name changed) |

### 9. Clean up

After a few days without issues:

```shell
aws s3 rb s3://prod-forge-todolist-web-client --force    # versioned: empty all versions first (console "Empty")
aws s3 rb s3://prod-forge-todolist-assets --force
aws ecr delete-repository --repository-name prod-forge-todolist --force
aws logs delete-log-group --log-group-name /ecs/prod-forge-todolist
aws logs delete-log-group --log-group-name /ecs/prod-forge-todolist-task-migration
aws rds delete-db-snapshot --db-snapshot-identifier prod-forge-migration
rm -f ~/prod-forge-state-before-migration.json   # the state copy contains secrets
```

Keep `prod-forge-migration-encrypted` until the next automated snapshots cover the restore window.

## Expected Downtime

- **API: about 30 to 75 minutes**, from scaling the service to 0 in step 4 until the new service is healthy in step 7. Most of it is the snapshot, the encrypted copy and the RDS restore with Multi-AZ; the ALB and the ECS service take a few minutes each.
- **Web client: none for static files.** The distribution is updated in place and the new buckets already hold the copied build. API calls from the page fail during the API window. Without a domain, the page keeps calling the old ALB DNS name until the frontend is rebuilt with the new `api_url`.
- **Client VPN and monitoring:** the VPN stays up (in-place update). Grafana is unavailable while the monitoring host is replaced and starts with empty history.

## Rollback

- **Before step 6** nothing that holds data has been deleted. Scale the old service back to 2 (`aws ecs update-service --cluster prod-forge-todolist-cluster --service prod-forge-todolist-service --desired-count 2`). To return Terraform to the old layout, push the saved state back (`terraform state push -force ~/prod-forge-state-before-migration.json` from a `main` checkout; the versioned state bucket also keeps every earlier version) and check out `main`. After the state push the following are unmanaged and must be deleted by hand or adopted again by a later roll forward: the NAT gateways and endpoints created in step 3, the new ECR repository `prod-forge-todolist-prod` and the new buckets `prod-forge-todolist-prod-web-client` and `prod-forge-todolist-prod-assets` created in step 5 (empty the buckets and the repository first), and the encrypted snapshot `prod-forge-migration-encrypted` together with `prod-forge-migration`.
- **After step 6** the old ALB, service and database are gone. Roll forward: fix the failing piece and re-apply. The data is safe in `prod-forge-migration` / `prod-forge-migration-encrypted`, the old buckets and the old ECR repository, which are all outside Terraform until step 9.

## Dev

Dev is new: `terraform -chdir=infrastructure/environments/dev init` creates its state under `environments/dev/terraform.tfstate`. Apply it after prod, because it reads the GitHub OIDC provider prod owns. See [Environments](environments.md#creating-dev).
