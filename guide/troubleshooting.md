# Troubleshooting

Production systems fail in unexpected ways.

When they do, the ability to diagnose problems quickly is what separates a minor incident from an extended outage.

This document covers common infrastructure issues encountered when running this stack in AWS — network
connectivity problems, routing failures, and service communication errors that are not always obvious from
logs alone.

These are not edge cases. They are the kinds of problems that appear during initial setup, after infrastructure
changes, and occasionally in stable production environments without warning.

Before reaching for this guide, make sure you have reviewed the [Debugging](debugging.md) document first.
Debugging covers how to connect to running services and inspect their state. This document assumes that
access is already established and focuses on diagnosing specific failure patterns.

## EC2/ECS + RDS Network Routing Connection

This section verifies whether network routing and security groups allow ECS or EC2 instances to reach the RDS database.

1. You need to connect to ECS or EC2 (see steps above)
2. Obtain the RDS hostname from the AWS Console:

```shell
mydb.abc123.eu-central-1.rds.amazonaws.com
```

3. Run the command in ECS/EC2:

```shell
nslookup mydb.abc123.eu-central-1.rds.amazonaws.com
```

Expected result:

```shell
Server: 127.0.0.53
Address: 127.0.0.53#53
```

If credentials are missing, you can still test port connectivity using nc:

```shell
nc -zv mydb.abc123.eu-central-1.rds.amazonaws.com 5432
```

Successful output:

```shell
Connection to mydb.abc123.eu-central-1.rds.amazonaws.com 5432 port [tcp/postgresql] succeeded!
```

This confirms that network routing and security groups are configured correctly.

## ECS tasks cannot pull the image

Symptoms: tasks stop right after `PROVISIONING` with `CannotPullContainerError` or `ResourceInitializationError` in the service events (`aws ecs describe-services` or the stopped task's `stoppedReason`).

1. Tasks run in private subnets, so they need a route to ECR: either a NAT gateway or the interface endpoints. Check that the private route table has `0.0.0.0/0` to a NAT gateway (`aws ec2 describe-route-tables`), or that `vpc_enable_endpoints = true` (prod) created the `ecr.api`, `ecr.dkr`, `secretsmanager`, `logs` and `ssmmessages` endpoints and they are `available`.
2. Image layers come from S3. The S3 gateway endpoint must be associated with the private route tables (it is always created), and the endpoint security group allows 443 from the VPC CIDR only, so a changed CIDR breaks it.
3. The image tag must exist in the environment's repository (`aws ecr describe-images --repository-name <project>-<environment>`). A fresh environment has only the `initial` image until the first release is pushed.
4. The task execution role must be able to read the secrets and use the KMS key (`secretsmanager:GetSecretValue`, `kms:Decrypt`); a missing permission shows up as `ResourceInitializationError: unable to pull secrets`.
5. Check the subnets and security groups of the service: egress 443 must be allowed from the ECS security group to the endpoints or the internet.

## Prometheus shows no targets

Prometheus finds the backend through AWS Cloud Map (`dns_sd_configs` on `backend.<namespace>`), not through a static address.

1. Open Prometheus (SSM port forward, see [Debugging](debugging.md)) -> Status -> Targets. An empty `nestjs-app` job means the DNS query returns nothing.
2. Check that the ECS service registered its tasks: `aws servicediscovery list-instances --service-id <backend service id>` should list one entry per running task. Tasks register only after they pass their health check and a deployment has finished.
3. Check the namespace in the rendered config: `<project>.local` in prod, `<project>-dev.local` in dev. The value in `prometheus.yml` must match the `service_namespace` of the environment.
4. From the monitoring host, run `nslookup backend.<namespace>`. No answer means the namespace is not attached to the VPC or the host uses a different resolver.
5. If the DNS answer is correct but the target is `DOWN`, the ECS security group must allow port 3000 from the monitoring security group and the backend must expose `/metrics`.
