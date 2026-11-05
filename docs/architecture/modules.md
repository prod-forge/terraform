# Modules

What each module provisions and how the domain switches HTTPS on. Roots, state and environments are in [overview.md](overview.md).

## Module list

`infrastructure/modules/stack/main.tf` calls every module below. Resource names are prefixed with
`${project}-${environment}`.

| Module                         | Provisions                                                                                                                                             |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `vpc`                          | VPC, the default security group taken over without rules, public and private subnets over `az_count` (default 2) AZs, IGW, NAT gateways (one, or one per AZ with `nat_per_az`), DB subnet group, flow logs, S3 gateway endpoint; interface endpoints (`ecr.api`, `ecr.dkr`, `secretsmanager`, `logs`, `ssmmessages`) only when `enable_vpc_endpoints` |
| `security_groups`              | security groups for the ALB, ECS, RDS, Redis and the VPN, with the ECS ingress/egress rules                                                            |
| `load_balancer`                | ALB with access logs, target group, HTTP listener, HTTPS listener (only with a domain), a listener rule that answers 404 on `/metrics*` and `/api/metrics*`; deletion protection when `environment == "prod"` |
| `logs-bucket`                  | S3 bucket for ALB and CloudFront access logs                                                                                                           |
| `waf`                          | WAFv2 web ACL; associated with the ALB when `scope = "REGIONAL"`. Called twice (ALB and CloudFront, the latter in `us-east-1`) when `enable_waf`        |
| `acm-certificate`              | ACM certificate with Route 53 DNS validation, only when `domain_name` is set. Called for the API (regional) and for CloudFront (`us-east-1`)            |
| `dns`                          | looks up the hosted zone and creates the API alias record and the web `A`/`AAAA` alias records, only when `domain_name` is set                          |
| `ecr`                          | ECR repository with a lifecycle policy, and the push policy for the backend deploy role                                                               |
| `github-oidc`                  | GitHub OIDC provider (created when `create_github_oidc_provider`, otherwise read as a data source) and the backend and frontend deploy roles           |
| `secrets_manager`              | KMS key, the app config secret, and generated Redis auth, JWT and Grafana admin secrets                                                                |
| `iam`                          | ECS task execution role and task role with secret read access                                                                                          |
| `ecs-cluster`                  | ECS cluster and its capacity providers                                                                                                                 |
| `task_definition`              | backend task definition and the CloudWatch log groups of the app and migration tasks                                                                    |
| `ecs-service`                  | ECS Fargate service, autoscaling target with CPU and request-count policies, deploy and `iam:PassRole` policies for the backend deploy role            |
| `service-discovery`            | Cloud Map private DNS namespace and the backend service                                                                                                |
| `rds`                          | PostgreSQL `aws_db_instance`, parameter group, enhanced monitoring role                                                                                 |
| `redis`                        | ElastiCache subnet group and replication group                                                                                                         |
| `frontend`                     | web client and assets S3 buckets, CloudFront distribution with OAC and a security headers policy, deploy policy for the frontend role                  |
| `observability-config`         | S3 bucket with the files of `infrastructure/observability/` (`*.tftpl` rendered with the Cloud Map namespace)                                         |
| `monitoring/iam`               | instance role and profile of the monitoring host (SSM, Grafana secret, config bucket)                                                                  |
| `monitoring/security_group`    | security group of the monitoring host                                                                                                                  |
| `monitoring/ec2`               | monitoring EC2 instance (Ubuntu 24.04, `templates/bootstrap.sh.tpl` user data, no key pair)                                                            |
| `alarms`                       | SNS topic (KMS-encrypted) with optional email subscription, CloudWatch alarms for ECS, ALB, RDS, Redis and NAT, optional monthly budget                 |
| `security-baseline`            | CloudTrail (bucket, KMS key, SNS topic), GuardDuty detector, IAM Access Analyzer, each behind its own flag                                             |
| `vpn/certificates/{server,client}` | imported ACM certificates for the Client VPN                                                                                                      |
| `vpn/vpn-endpoint`             | Client VPN endpoint (split tunnel, DNS at the VPC base address plus two, client CIDR `10.200.0.0/22` by default) and its connection log group (30 days) |
| `vpn/associations`             | Client VPN association with the first private subnet                                                                                                   |
| `vpn/rules`                    | Client VPN authorization rule for the VPC CIDR                                                                                                         |

All `vpn/*` modules are created only when `enable_client_vpn`. The stack itself adds one resource: the ECS ingress
rule on port 3000 from the monitoring security group (Prometheus scrape).

Modules declare only `required_version` and `required_providers`; providers are configured in the environment roots. `stack` declares
`configuration_aliases = [aws.us_east_1]`.

---

## Conditional HTTPS

Everything domain-related keys off `var.domain_name` (empty in both `terraform.tfvars` today):

- `acm-certificate` and `dns`: `enabled = var.domain_name != ""`, resources use `count`
- `load_balancer`: `https_enabled = var.domain_name != ""`; with a domain the HTTP listener redirects to the HTTPS
  listener, without one it forwards to the target group (plain HTTP)
- `frontend`: with a domain CloudFront gets the alias and the `us-east-1` ACM certificate, otherwise the default
  CloudFront certificate
- `stack`: `api_url` is `https://<api_subdomain>.<domain_name>` with a domain, otherwise `http://<alb dns name>`;
  CORS origins are the custom domain (when set) and the CloudFront domain
