# Backup and Disaster Recovery (RDS)

The PostgreSQL instance is the only stateful component that cannot be rebuilt from code. This page describes what protects it and how to recover.

## Protection in place

| Mechanism | Setting | Effect |
| --- | --- | --- |
| Automated backups | `backup_retention_period` = 7 days in prod (1 in dev) | Daily snapshot plus continuous transaction log archiving |
| Point-in-time recovery (PITR) | Enabled by automated backups | Restore to any second inside the retention window, up to about 5 minutes before now |
| Multi-AZ | `multi_az = true` in prod | Synchronous standby in a second Availability Zone with automatic failover |
| Deletion protection | `deletion_protection = true` in prod | The instance cannot be deleted until the flag is turned off |
| Final snapshot | `skip_final_snapshot = false`, id `<project>-<env>-final` | A snapshot is taken if the instance is ever destroyed |
| Encryption | KMS CMK from the `secrets_manager` module | Storage, snapshots, Performance Insights and the master secret are encrypted |
| Snapshot tags | `copy_tags_to_snapshot = true` | Snapshots keep the instance tags |

## Objectives

- **RPO: about 5 minutes.** Transaction logs are shipped to S3 roughly every 5 minutes, so PITR can restore to the latest restorable time reported by RDS. A Multi-AZ failover loses no committed data (synchronous replication).
- **RTO, instance or AZ failure: about 60 to 120 seconds.** Multi-AZ promotes the standby and flips the DNS endpoint; the application reconnects without configuration changes.
- **RTO, data corruption or accidental delete: 30 to 60 minutes** for a restore into a new instance, depending on database size, plus the time to switch the application over.

## Restore procedure

A restore always creates a new instance. The original is left untouched so it can be inspected.

1. Find the restore point.

   ```bash
   aws rds describe-db-instances --db-instance-identifier prod-forge-todolist-prod-postgres \
     --query 'DBInstances[0].LatestRestorableTime'
   aws rds describe-db-snapshots --db-instance-identifier prod-forge-todolist-prod-postgres \
     --query 'DBSnapshots[].[DBSnapshotIdentifier,SnapshotCreateTime]' --output table
   ```

2. Restore to a new instance, either to a point in time or from a snapshot.

   ```bash
   # Point in time
   aws rds restore-db-instance-to-point-in-time \
     --source-db-instance-identifier prod-forge-todolist-prod-postgres \
     --target-db-instance-identifier prod-forge-todolist-prod-postgres-restore \
     --restore-time 2026-01-01T10:00:00Z \
     --db-subnet-group-name <subnet-group> --vpc-security-group-ids <rds-sg-id> \
     --db-parameter-group-name <parameter-group>

   # From a snapshot (use the `<project>-<env>-final` snapshot after a deletion)
   aws rds restore-db-instance-from-db-snapshot \
     --db-snapshot-identifier <snapshot-id> \
     --db-instance-identifier prod-forge-todolist-prod-postgres-restore \
     --db-subnet-group-name <subnet-group> --vpc-security-group-ids <rds-sg-id> \
     --db-parameter-group-name <parameter-group>
   ```

3. Wait until the instance is available.

   ```bash
   aws rds wait db-instance-available --db-instance-identifier prod-forge-todolist-prod-postgres-restore
   ```

4. Verify the data through the VPN (see [Debugging](debugging.md)) with `psql`: row counts and the newest records of the main tables.
5. Switch the application to the restored instance. Prefer reconciling Terraform instead of editing the endpoint by hand: either import the restored instance under the module address (`terraform import`) after removing the broken one from state, or rename the restored instance to the identifier Terraform expects (`<project>-<environment>-postgres`). Review the plan before applying.
6. Keep the old instance until the application is confirmed healthy, then remove it (turn off deletion protection first, and keep its final snapshot).

The restored instance gets its own master user secret only if `manage_master_user_password` is set in the restore call; otherwise reuse the existing credentials and rotate them afterwards.

## Quarterly restore drill

Run once per quarter in a non-production account or with a throwaway identifier, and record the date and result.

- [ ] Pick a restore point (latest snapshot and one PITR time).
- [ ] Restore both into new instances with the commands above.
- [ ] Record the elapsed time from the restore call to `available`; compare with the RTO.
- [ ] Connect through the VPN and check row counts against production.
- [ ] Run the application migrations against the restored copy in dry-run mode.
- [ ] Trigger a Multi-AZ failover with `aws rds reboot-db-instance --force-failover` on a non-production instance and measure the downtime.
- [ ] Delete the drill instances and confirm no orphan snapshots or costs remain.
- [ ] File follow-ups for anything that took longer than expected or was unclear.

## Not covered

- **Cross-region disaster recovery.** Backups and the standby live in one region. A full regional outage means waiting for the region to recover. Cross-region automated backup replication or a cross-region read replica would close this gap at extra cost.
- **Logical errors discovered after the retention window.** PITR only reaches back 7 days in prod. Longer retention needs manual or AWS Backup snapshots.
- **Redis.** The cache is treated as disposable and is not backed up here.
- **Application-level backups** such as exports to S3.
