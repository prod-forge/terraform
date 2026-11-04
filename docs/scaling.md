# Scaling

How the backend service scales on ECS Fargate, which knobs exist, and how to check that the policies actually fire.

## Capacity model

| Setting | Dev (`environments/dev/terraform.tfvars`) | Prod (`environments/prod/terraform.tfvars`) |
| --- | --- | --- |
| Task size (`cpu` / `memory`) | 256 / 512 MiB | 512 / 1024 MiB |
| Initial `desired_count` | 1 | 2 |
| Auto scaling `min_capacity` | 1 | 2 |
| Auto scaling `max_capacity` | 2 | 10 |
| NAT gateways | 1 shared | 1 per AZ |
| Interface VPC endpoints | off | on |

- Tasks run in the private subnets of two AZs (`az_count = 2`) without public IPs. With `min_capacity = 2` the scheduler spreads tasks across both AZs, so losing one AZ leaves the service up.
- `desired_count` only sets the starting value. After the first apply, Application Auto Scaling owns it and Terraform ignores drift on it (`lifecycle.ignore_changes`).
- Peak capacity is `max_capacity` × task size: prod tops out at 10 × 0.5 vCPU / 1 GiB. RDS connections are the real ceiling: every task opens its own Prisma pool, so check `max_connections` on the DB instance before raising `max_capacity`.

## Scaling policies

Both policies are target tracking on the same scalable target (`ecs:service:DesiredCount`). Application Auto Scaling scales out if either policy asks for it and scales in only when both allow it.

| Policy | Metric | Target | Scale-out cooldown | Scale-in cooldown |
| --- | --- | --- | --- | --- |
| `<project>-<environment>-cpu-target-tracking` | `ECSServiceAverageCPUUtilization` | 60% | 60 s | 300 s |
| `<project>-<environment>-alb-requests-target-tracking` | `ALBRequestCountPerTarget` (`resource_label` = `<alb arn suffix>/<target group arn suffix>`) | 1000 requests per task per minute | 60 s | 300 s |

- CPU catches expensive requests; the request count policy catches many cheap requests that do not move CPU much (I/O bound handlers waiting on RDS or Redis).
- Scale-in is slow on purpose: a task needs up to 60 s to stop (`stopTimeout`, see below), and flapping costs more than a few extra minutes of capacity.
- Targets are module variables (`cpu_target_value`, `requests_per_target_value`). Tune them from load test results, not guesses.

## Deployments and shutdown

- Rolling deployments (`deployment_controller = ECS`), `minimum_healthy_percent = 100`, `maximum_percent = 200`: new tasks start before old ones stop.
- The deployment circuit breaker is on with `rollback = true`: if new tasks keep failing health checks, ECS marks the deployment failed and rolls back to the last steady task definition.
- `health_check_grace_period_seconds = 60` gives the app time to boot before failing ALB health checks count.
- `stopTimeout = 60`: on SIGTERM the backend drains for 10 s, then waits up to 20 s for in-flight requests before exiting. 60 s covers those 30 s with headroom before ECS sends SIGKILL. If the backend drain or in-flight timeouts grow, `stopTimeout` must stay above their sum (Fargate allows at most 120 s). ECS deregisters the task from the ALB target group (`deregistration_delay = 30` s on the target group, matching the backend drain of about 30 s) before it sends SIGTERM, so the delay lengthens deployments slightly but does not cut requests. Keep the delay at or below `stopTimeout`.

## How to load-test the policies

Run against a non-production environment, or against prod only in a maintenance window.

1. Pick a load generator, for example [k6](https://k6.io/) or `hey`, and an endpoint that exercises the database (an authenticated list call), not `/health`.
2. Ramp the load in steps, holding each step for at least 5 minutes, because target tracking alarms evaluate over several 1-minute datapoints:

   ```shell
   hey -z 10m -c 50 -H "Authorization: Bearer <TOKEN>" http://<ALB_DNS>/<ENDPOINT>
   ```

3. Watch the scaling activity and the alarms that Application Auto Scaling created:

   ```shell
   aws application-autoscaling describe-scaling-activities \
     --service-namespace ecs \
     --resource-id service/<CLUSTER_NAME>/<SERVICE_NAME>

   aws cloudwatch describe-alarms --alarm-name-prefix TargetTracking-service/<CLUSTER_NAME>/<SERVICE_NAME>
   ```

4. Confirm in Container Insights (CloudWatch → Container Insights, enhanced observability) that CPU per task drops back near the target after the scale-out.
5. Stop the load and confirm that the service scales back in to `min_capacity` after the scale-in cooldowns.

A test passes when the service scales out before p99 latency or the error rate degrades, and never goes above `max_capacity`. If it hits `max_capacity` under expected peak load, raise the limit or the task size.

## Fargate Spot trade-off

The cluster registers both `FARGATE` and `FARGATE_SPOT` capacity providers with a default strategy of 100% `FARGATE`.

- Spot is up to ~70% cheaper, but AWS may reclaim a task with a two-minute warning. The backend shuts down cleanly within 30 s, so a reclaimed task does not drop requests, but capacity drops until a replacement starts.
- It suits dev environments and extra capacity above the baseline (for example `base = 2` on `FARGATE`, the remainder weighted toward `FARGATE_SPOT`). It does not suit the baseline tasks in prod.
- The service currently sets `launch_type = "FARGATE"`, so the cluster default strategy does not apply to it. Moving the service to a `capacity_provider_strategy` replaces the `aws_ecs_service` resource, so plan that change as a deliberate migration with a maintenance window.
