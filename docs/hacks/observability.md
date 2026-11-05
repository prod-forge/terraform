# Observability hacks

<!-- cspell:ignore templatefile -->

## Stale docs/observability.md mentions

- **What:** two comments still point to `docs/observability.md`, which no longer exists; the chapter is now `guide/observability.md`. They are left as they are on purpose.
- **Where:** `infrastructure/modules/monitoring/ec2/templates/bootstrap.sh.tpl` ("Sync script, also used to roll out changed configuration (see docs/observability.md)"); `infrastructure/observability/promtail/config.yml` (header comment, "see docs/observability.md").
- **Why:** both files are deployed byte for byte. `bootstrap.sh.tpl` is rendered with `templatefile` into the `user_data` of `aws_instance.monitoring`, which sets `user_data_replace_on_change = true`; `promtail/config.yml` is uploaded by `aws_s3_object.plain` in `infrastructure/modules/observability-config/main.tf`, whose `source_hash` is the file's MD5.
- **If cleaned up:** fixing the template comment changes the user data and the next apply replaces the monitoring EC2 instance (the Docker volumes with metrics, logs and Grafana state live on its root volume and are lost, `guide/observability.md`, "Rolling out configuration changes"). Fixing the Promtail comment re-uploads the object; that is harmless but shows up as a change in every environment. Fix both only together with a change that replaces the host anyway.

## Monitoring host replaced on user data change

- **What:** `user_data_replace_on_change = true` on the monitoring instance.
- **Where:** `infrastructure/modules/monitoring/ec2/main.tf`.
- **Why:** the bootstrap script runs only on first boot; without a replacement a changed script would never run (`guide/observability.md`, "Rolling out configuration changes"). Changed configuration files are rolled out without a replacement through the `observability-sync` script on the host, run over SSM (`guide/observability.md`).
- **If cleaned up:** removing it leaves hosts running an old bootstrap; keeping it means any edit of `bootstrap.sh.tpl`, the region, the bucket or the Grafana secret ARN replaces the host.

## AMI changes are ignored

- **What:** `lifecycle { ignore_changes = [ami] }` on the monitoring instance, whose AMI is read from the Canonical SSM parameter.
- **Where:** `infrastructure/modules/monitoring/ec2/main.tf` (comment in the file).
- **Why:** the parameter changes with every Ubuntu image release; AMI updates are rolled out deliberately (taint or replace).
- **If cleaned up:** every plan after a new Ubuntu image replaces the monitoring host.

## source_hash instead of etag

- **What:** the observability config objects use `source_hash`, not `etag`.
- **Where:** `aws_s3_object.plain` and `aws_s3_object.rendered` in `infrastructure/modules/observability-config/main.tf` (comment in the file).
- **Why:** the bucket is KMS-encrypted, and the ETag of a KMS-encrypted object is not its MD5.
- **If cleaned up:** with `etag`, every plan shows a diff for every object.

## Bucket name output waits for the objects

- **What:** `depends_on = [aws_s3_object.plain, aws_s3_object.rendered]` on the `bucket_name` output.
- **Where:** `infrastructure/modules/observability-config/outputs.tf` (comment in the file).
- **Why:** the monitoring host syncs the files at first boot; the output feeds its user data, so the instance is created only after the objects exist.
- **If cleaned up:** the host can boot before the files are uploaded and start with an empty configuration.

## Promtail config differs from the backend copy

- **What:** `infrastructure/observability/promtail/config.yml` is a synced copy of the backend's `observability/promtail/promtail-config.yml`, with no `logging` label and no JSON stage.
- **Where:** header comment of the file.
- **Why:** containers on the monitoring host carry no `logging` label and do not log pino JSON; ECS task logs go to CloudWatch Logs, not to Promtail.
- **If cleaned up:** copying the backend file over it unchanged drops the host's container logs.
