# Blue/Green Deployment

Status: **not implemented**. This is a design note for a possible future change. The service deploys with the ECS rolling update today.

## Why

The rolling deployment (`deployment_controller` type `ECS`, circuit breaker with rollback, 200% maximum and 100% minimum healthy) replaces tasks in place. A bad release is caught by the circuit breaker, but the rollback is another rolling update, and during a deployment old and new versions serve traffic at the same time. Blue/Green runs the new version next to the old one, tests it before it takes traffic, and rolls back by moving the listener back, in seconds.

## What changes in the service

The approach is ECS with AWS CodeDeploy:

- `ecs-service`: `deployment_controller { type = "CODE_DEPLOY" }`. The task definition, desired count and load balancer settings are then owned by CodeDeploy deployments, so `task_definition` and `load_balancer` must be listed in `lifecycle.ignore_changes` of the service. The circuit breaker settings are not used with this controller.
- `load_balancer`: a second target group (`green`) and a test listener (for example port 8080, restricted to the VPN or office CIDR) that points at it. The production listener keeps pointing at the `blue` target group until traffic is shifted. With a domain, the test listener also needs an HTTPS certificate or stays internal.
- New module `codedeploy`: an application (`ECS` compute platform), a deployment group that references the cluster, the service, both target groups and both listeners, the traffic routing (`CodeDeployDefault.ECSAllAtOnce`, or a canary/linear configuration such as `ECSCanary10Percent5Minutes`), automatic rollback on failure or alarm, and termination of the old task set after a wait time.
- `alarms`: reuse the ALB 5xx and unhealthy-host alarms as CodeDeploy rollback triggers.
- IAM: a CodeDeploy service role (`AWSCodeDeployRoleForECS`) and `codedeploy:CreateDeployment`, `GetDeployment`, `GetDeploymentConfig`, `RegisterApplicationRevision` plus `ecs:RegisterTaskDefinition` and `iam:PassRole` for the GitHub deploy role.
- Tests: add `terraform test` cases for the controller type and the two target groups, with the negative cases first.

## What changes in the CD workflow

Today `cd.yml` registers a new task definition and calls `aws ecs update-service`. With CodeDeploy:

1. Render the task definition with the new image tag (unchanged).
2. Instead of `update-service`, use `aws-actions/amazon-ecs-deploy-task-definition` with `codedeploy-appspec`, `codedeploy-application` and `codedeploy-deployment-group`, or call `aws deploy create-deployment` with an `appspec.yaml` that names the task definition, container and port.
3. Wait for the deployment to finish (`aws deploy wait deployment-successful`). Failure or an alarm during the test or shifting phase rolls back to blue without a workflow step.
4. `rollback.yml` creates a deployment of the previous task definition, or stops the running deployment with `aws deploy stop-deployment --auto-rollback-enabled`.
5. Database migrations stay a separate one-off task before the deployment. They must remain backward compatible, because blue and green share one database (see [Workflow](workflow.md)).

## Trade-offs

- Rollback becomes immediate, and the new version can be smoke-tested through the test listener before any user reaches it.
- Capacity doubles for the length of the deployment (blue and green tasks run together); with Fargate that is a few minutes of extra cost per release.
- More moving parts: a second target group, a second listener, CodeDeploy, its IAM roles, and `ignore_changes` on service attributes. Drift between Terraform and the live service is harder to read.
- Schema changes need the expand and contract pattern for both versions to work against the same database.
- The Prometheus discovery through Cloud Map keeps working, but the green tasks register in Cloud Map as well, so dashboards show both versions while they overlap.
