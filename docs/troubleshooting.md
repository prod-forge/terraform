# Troubleshooting

## EC2/ECS + RDS Network Routing Connection

Checking whether there is access from ECS / EC2 to the database

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
