# Security

How traffic is protected from the browser to the data stores, and which controls are deliberately not in place yet.

## TLS everywhere

| Hop | Protection |
| --- | --- |
| Browser → CloudFront | HTTPS only (`redirect-to-https`). With a custom domain: ACM certificate from `us-east-1`, SNI, minimum `TLSv1.2_2021` |
| Browser → ALB | With a domain: 443 listener with `ELBSecurityPolicy-TLS13-1-2-2021-06` (TLS 1.3 and 1.2 only) and port 80 answering `301` to HTTPS |
| CloudFront → S3 | Origin Access Control with SigV4 signing; buckets block all public access |
| ECS → RDS | TLS required: the parameter group sets `rds.force_ssl = 1` explicitly (also the RDS default for PostgreSQL 15 and later; the instance runs 18) |
| ECS → Redis | In-transit encryption and an AUTH token |
| ECS → AWS APIs | HTTPS through VPC endpoints or the NAT gateway |

Certificates come from the `acm-certificate` module: one DNS-validated certificate for `api.<domain>` in the deployment region (ALB) and one for `<domain>` in `us-east-1` (CloudFront). Validation records are written to the Route 53 zone named by `hosted_zone_name` (defaults to `domain_name`), and ACM renews them automatically while the records exist.

### Without a domain (insecure fallback)

HTTPS is enabled only when `domain_name` is set. With `domain_name = ""` (the current value in both `environments/*/terraform.tfvars`) Terraform creates no certificate, no 443 listener and no DNS records, and the ALB keeps forwarding plain HTTP on port 80.

> **Warning:** in this mode API traffic, including credentials and tokens, crosses the internet unencrypted. It is meant only for a first deployment before a domain is available. Set `domain_name` (and `hosted_zone_name` if the zone is a parent domain) before real users touch the system.

The web client is still served over HTTPS on the `*.cloudfront.net` domain, but the default CloudFront certificate allows TLS 1.0, so the TLS 1.2 minimum also requires the custom domain.

## WAF

Two web ACLs come from the `waf` module, one per scope:

| ACL | Scope | Attached to |
| --- | --- | --- |
| `<project>-<env>-regional` | `REGIONAL` | the ALB, through `aws_wafv2_web_acl_association` |
| `<project>-<env>-cloudfront` | `CLOUDFRONT` (created through the `aws.us_east_1` provider) | the distribution, through `web_acl_id` |

Both run the same rules, in this order:

| Priority | Rule | Why |
| --- | --- | --- |
| 10 | `AWSManagedRulesAmazonIpReputationList` | Drops traffic from IPs that AWS threat intelligence marks as bots, scanners or malware sources, before any other rule spends capacity on them |
| 20 | `AWSManagedRulesCommonRuleSet` | OWASP Top 10 baseline: XSS, path traversal, oversized or malformed requests. Note that `SizeRestrictions_BODY` blocks request bodies over 8 KB |
| 30 | `AWSManagedRulesKnownBadInputsRuleSet` | Request patterns of known exploits, including Log4Shell and Java deserialization |
| 40 | `rate-limit-per-ip` | Blocks a client IP that sends more than 2000 requests in 5 minutes (`rate_limit`), which limits credential stuffing and cheap floods |

The default action is `allow`. Every rule publishes CloudWatch metrics and sampled requests (`AWS/WAFV2` namespace). Full request logging is not enabled yet, to bound cost.

If a managed rule blocks legitimate traffic, override that single rule to `count` inside its rule group (`rule_action_override`) rather than removing the group.

## Response headers

The CloudFront response headers policy (see [Frontend](frontend.md#security-headers)) sets HSTS for two years with `includeSubDomains`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin` and the full `Content-Security-Policy` (enforced in production; the web client `index.html` ships the same policy in a meta tag, which cannot carry `frame-ancestors`, see [Frontend](frontend.md#security-headers)). Without a domain the API origin is plain HTTP on the ALB, which an HTTPS page cannot call (mixed content); that setup is for infrastructure smoke tests only. HSTS `preload` stays off because leaving the preload list takes months; enable it only once every subdomain serves HTTPS.

## Load balancer hardening

- `drop_invalid_header_fields = true`: requests with malformed header names are dropped instead of being passed to the app (request smuggling defense).
- Deletion protection is on when `environment = "prod"`.
- Access logs go to the `<project>-<env>-access-logs` bucket under `alb/`.

## Metrics endpoints

The backend serves `/metrics` and `/metrics/database` without authentication. The primary control is in the backend, which answers 404 to metrics requests that came through the ALB (`X-Forwarded-For` present), with or without the `/api` prefix. As defence in depth, a listener rule with priority 1 returns a fixed 404 for the path patterns `/metrics*` and `/api/metrics*` on the forwarding listener (443 with a domain, 80 without). ALB path matching is case-sensitive, so the rule alone is not a complete barrier. Prometheus scrapes the task IPs on port 3000 directly and is not affected.

## Access logs

The `logs-bucket` module creates one bucket for ALB access logs (`alb/`) and CloudFront standard logs (`cloudfront/`):

- objects expire after 90 days (`retention_days`), noncurrent versions after 1 day;
- SSE-S3 encryption, because ALB log delivery does not support SSE-KMS;
- object ownership `BucketOwnerPreferred`, because CloudFront standard logging writes through the `awslogsdelivery` ACL grant;
- public access blocked, a bucket policy that grants write only to ELB log delivery (CloudFront writes through its ACL grant instead) and denies non-TLS requests.

## Security groups

| Group | Ingress | Egress |
| --- | --- | --- |
| ALB | 80 and 443 from `0.0.0.0/0` | 3000 to the VPC CIDR (targets and health checks) |
| ECS | 3000 from the ALB group and the monitoring host | 443 anywhere, 5432 to RDS, 6379 to Redis |
| RDS | 5432 from the ECS and VPN groups | none |
| Redis | 6379 from the ECS and VPN groups | none |
| Client VPN | all from the VPC CIDR | all to the VPC CIDR |
| Monitoring host | 3000 from `admin_cidr_blocks` | all (packages, images, AWS APIs) |
| VPC endpoints | 443 from the VPC CIDR | none |
| VPC default group | none | none (taken over by Terraform and left without rules, so nothing placed in it can talk) |

The ALB is the only public entry point for the API. ECS tasks run in private subnets without public IPs. RDS and Redis need no egress rules because security groups are stateful. Groups use `name_prefix` (`<project>-<env>-<role>-sg-`) with `create_before_destroy`, so rule changes never leave dependents without a group.

## IAM

- GitHub Actions authenticate through OIDC (no static keys) and use one role per repository: the backend role gets ECR push and ECS deploy, the frontend role gets the web client deploy (S3 sync and `cloudfront:CreateInvalidation` on the one distribution). Trust is limited to the repository and its GitHub environment (`environment:prod` for the prod roles, `environment:dev` for dev). The ECR repository has immutable tags, scan on push and KMS encryption.
- The ECS execution role reads only the secrets the task needs (RDS, Redis AUTH, JWT, the app config secret; policy `<project>-<env>-ecs-secrets-read`) and decrypts them with the project KMS key, which rotates yearly.
- The monitoring EC2 role reads the Grafana admin secret (and decrypts it with the project KMS key), reads the observability config bucket and uses SSM Session Manager (`AmazonSSMManagedInstanceCore`). It has no ECR access: the observability images come from public registries.
- Every role and policy name starts with `<project>-<env>-`, so the IAM permissions of the Terraform operator can be scoped to that prefix.

## Monitoring host

- No SSH key pair and no port 22; access is through SSM Session Manager only.
- Ingress is Grafana (3000) from `admin_cidr_blocks` only; an empty list creates no rule. Prometheus (9090) is not exposed.
- IMDSv2 required, encrypted gp3 root volume, detailed monitoring, EBS optimized, AMI resolved from the Canonical SSM parameter.
- Alarm notifications go through a KMS-encrypted SNS topic (see [observability](observability.md#alarms)).

## Account security baseline

The `security-baseline` module turns on the account-wide detective controls. They exist once per account, so exactly one environment owns them: `enable_account_security_services = true` in prod, `false` in dev while both share an account (set it to `true` for a dev in its own account).

| Service | Resource | Configuration |
| --- | --- | --- |
| CloudTrail | `<project>-<env>-trail` | Multi-region, global service events (IAM, STS), log file validation (digest files), encrypted with a dedicated rotating CMK, a notification per delivered log file to the KMS-encrypted SNS topic `<project>-<env>-cloudtrail` |
| CloudTrail bucket | `<project>-<env>-cloudtrail` | Versioned, SSE-KMS with the trail key, ACLs disabled, public access blocked, TLS only, writes only from this trail (`aws:SourceArn`); log files move to Glacier Instant Retrieval after 90 days and expire after 365 (`cloudtrail_archive_after_days`, `cloudtrail_retention_days`) |
| GuardDuty | detector in the deployment region | Enabled, findings published every 15 minutes; analyzes CloudTrail management events, VPC flow logs and DNS logs. The optional protection plans (S3, EKS, RDS, malware, runtime) stay off to bound cost |
| IAM Access Analyzer | `<project>-<env>-access-analyzer` | Account zone of trust: reports S3 buckets, KMS keys, IAM roles, secrets and other resources shared outside the account |

Where to look:

- **CloudTrail:** Console → CloudTrail → Event history covers 90 days without the trail; the bucket keeps a year. Verify integrity with `aws cloudtrail validate-logs --trail-arn <arn> --start-time <time>`.
- **GuardDuty:** Console → GuardDuty → Findings. Findings are not routed to the alerts SNS topic yet; check them weekly or add an EventBridge rule (`source = aws.guardduty`, severity 7 and above) that targets a topic.
- **Access Analyzer:** Console → IAM → Access analyzer. Archive findings that describe intended sharing; anything else is a resource reachable from outside the account.

GuardDuty and Access Analyzer are regional: they cover the deployment region only. The trail covers all regions.

## Known gaps

Checkov reports no failed checks; the accepted exceptions and their reasons are the inline skips listed in [CI](ci.md#baseline). GuardDuty findings are not paged yet (see above), and AWS Config is not enabled.
