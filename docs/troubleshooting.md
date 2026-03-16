# Troubleshooting

Production systems fail in unexpected ways.

When they do, the ability to diagnose problems quickly is what separates a minor incident from an extended outage.

This document covers common infrastructure issues encountered when running this stack in AWS — network
connectivity problems, routing failures, and service communication errors that are not always obvious from
logs alone.

These are not edge cases. They are the kinds of problems that appear during initial setup, after infrastructure
changes, and occasionally in stable production environments without warning.

Before reaching for this guide, make sure you have reviewed the [Debugging](https://github.com/prod-forge/terraform/blob/main/docs/debugging.md) document first.
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
