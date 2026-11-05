# Cost

Approximate monthly cost of each environment in `eu-central-1`, at on-demand list prices, for 730 hours and light traffic. Data transfer, NAT and endpoint data processing, CloudFront and S3 requests, log ingestion beyond a few GB and Client VPN connection hours come on top. Use the [AWS Pricing Calculator](https://calculator.aws/) for a binding number; the tables show where the money goes.

## Monthly Estimate

| Item | dev | prod | Notes |
| --- | --- | --- | --- |
| NAT gateways | 38 | 76 | 1 shared vs 1 per AZ, plus 0.052 USD per processed GB |
| Interface VPC endpoints | 0 | 88 | 5 endpoints (`ecr.api`, `ecr.dkr`, `secretsmanager`, `logs`, `ssmmessages`) in 2 AZs |
| ALB | 22 | 25 | hourly charge plus LCUs |
| ECS Fargate | 10 | 41 | 1 x 0.25 vCPU / 0.5 GiB vs 2 x 0.5 vCPU / 1 GiB at minimum capacity |
| RDS PostgreSQL | 17 | 120 | `db.t4g.micro` single AZ vs `db.t4g.medium` Multi-AZ, 20 GiB storage |
| ElastiCache Redis | 13 | 53 | 1 `cache.t4g.micro` vs 2 `cache.t4g.small` |
| Monitoring host | 20 | 20 | `t3.small` plus 30 GiB gp3 |
| Client VPN | 0 | 73 | one subnet association, plus 0.05 USD per connection hour |
| WAF | 0 | 18 | 2 web ACLs with 4 rules each, plus requests |
| Public IPv4 addresses | 15 | 18 | NAT, ALB and monitoring host addresses at 0.005 USD per hour |
| CloudWatch (logs, alarms, Container Insights) | 8 | 25 | grows with VPC flow log and application log volume |
| Secrets Manager, KMS, S3, CloudFront | 7 | 10 | 5 secrets (4 project secrets plus the RDS-managed master secret), 2 to 3 CMKs, low-traffic buckets and distribution |
| CloudTrail, GuardDuty, Access Analyzer | 0 | 10 | first trail copy of management events is free; GuardDuty bills analyzed events and flow/DNS log volume; the account analyzer is free; prod owns them for the shared account |
| **Total** | **about 150** | **about 580** | |

## Budget

`aws_budgets_budget` has no cost filter, so it measures the spend of the whole account, not of one environment. It is therefore an account singleton, like CloudTrail and GuardDuty: prod owns it with `monthly_budget_usd = 800`, above the combined estimate of dev and prod (about 730 USD), and dev sets `monthly_budget_usd = 0` (no budget) while both share an account. Alerts go to `alert_email` at 80% (640 USD) and 100% of actual spend. Without dev in the account, lower it to about 600 USD; with a separate dev account, give dev its own budget of about 200 USD. Use Cost Explorer grouped by the `Environment` tag to see which environment drives the total.

## Main Levers

- **Client VPN (prod, about 73 USD).** The endpoint association bills every hour. Without it, Session Manager port forwarding reaches Grafana on the monitoring host, and RDS and Redis through a running backend task with ECS Exec (see [Debugging](debugging.md)); set `enable_client_vpn = false` if nobody needs the VPN.
- **NAT gateways (38 USD each).** `vpc_nat_per_az = false` keeps one shared gateway at the cost of losing egress when its AZ fails. Interface endpoints reduce NAT data processing, not the hourly charge.
- **Interface endpoints (about 88 USD).** Worth it when image pulls, logs and secret reads move many GB through NAT; for a quiet environment NAT alone is cheaper (`vpc_enable_endpoints = false`).
- **RDS Multi-AZ (doubles the instance cost).** Keep it in prod for the 60 to 120 second failover; dev runs single AZ.
- **Redis replica.** `redis_num_cache_clusters = 1` halves the Redis cost and drops automatic failover.
- **Fargate Spot.** Up to about 70% cheaper for interruption-tolerant tasks; see [Scaling](scaling.md#fargate-spot-trade-off).
- **Stop dev when idle.** Scale the ECS service to 0 and stop the RDS instance (AWS restarts it after 7 days), or `terraform destroy` dev entirely; it recreates under the same names.
- **Log volume.** Flow logs capture all traffic; shorter `flow_logs_retention_days` and `ecs_log_retention_days` cap storage, ingestion is billed per GB.
- **GuardDuty volume.** Its cost follows CloudTrail events and VPC flow/DNS log volume; the 30-day free trial on a new account shows the expected bill under GuardDuty → Usage.
- **Tags.** `CostCenter`, `Environment` and `Project` come from `default_tags`; activate them as cost allocation tags in Billing to split Cost Explorer by environment.
