# Frontend Deployment (Web Client)

Static files in S3, served globally through CloudFront.

No servers, no containers, no runtime processes to manage.

## Architecture

```text
CI/CD → build → S3 (web-client bucket)
                S3 (assets bucket)
                      ↓
               CloudFront CDN
                      ↓
                  Browser
```

Two S3 buckets are used:

- **web-client** — SPA build output (index.html, JS, CSS bundles)
- **assets** — shared static files (images, fonts, and other media)

Both buckets are fully private. Content is only accessible through CloudFront using Origin Access Control (OAC) with SigV4 request signing.

```text
Browser → CloudFront → [SigV4 signed] → S3
```

The raw S3 URLs are never exposed.

The web-client bucket is versioned. Previous object versions (overwritten or deleted by a deploy) expire after 30 days (`noncurrent_version_expiration_days`), so an accidental `sync --delete` can be undone from S3 versions in addition to the `releases/` archive.

## Custom Domain

Set `domain_name` in the environment tfvars (and `hosted_zone_name` when the Route 53 zone is a parent domain). Terraform then:

1. Issues an ACM certificate for `<domain>` in `us-east-1` (CloudFront accepts certificates only from there) and validates it through a DNS record in the zone.
2. Adds `<domain>` to the distribution `aliases` and serves it with SNI and a `TLSv1.2_2021` minimum.
3. Creates `A` and `AAAA` alias records for `<domain>` pointing to the distribution (IPv6 is enabled on it), and an `A` alias for `api.<domain>` pointing to the ALB.

With `domain_name = ""` the distribution keeps the default `*.cloudfront.net` certificate and no records are created. `terraform output cloudfront_url` and `terraform output api_url` always return the URLs to use for the web client build and the CSP in `index.html`.

## WAF and Access Logs

The distribution is protected by a `CLOUDFRONT`-scope WAF web ACL (managed IP reputation, common and known-bad-inputs rules, 2000 requests per IP per 5 minutes); see [Security](security.md#waf). Standard access logs are written to the shared access-logs bucket under `cloudfront/` and expire after 90 days.

## Security Headers

A CloudFront response headers policy is attached to every cache behavior: `Strict-Transport-Security` (2 years, includeSubDomains), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, and the full `Content-Security-Policy`.

The header is the enforced source of truth for the CSP in production. The web client `index.html` also ships the policy in a `<meta>` tag, kept identical: the two match when `VITE_ASSETS_BASE_URL` is unset or same-origin, otherwise the meta tag adds the assets origin, both policies are enforced and the stricter header wins. Only the header can carry `frame-ancestors`; browsers ignore it in a meta tag. The only variable part is the API origin in `connect-src`, passed to the module as `api_origin`: `https://api.<domain>` with a domain, `http://<alb-dns>` without one (the stack passes its `api_url` output). The web client assets are served by the same distribution under `/assets`, so `'self'` covers them. `https://*.sentry.io` covers the Sentry ingest host. There is no `unsafe-eval`.

The no-domain setup (`domain_name = ""`) is for infrastructure smoke tests only: the page is served over HTTPS on `*.cloudfront.net` while the API origin is plain HTTP on the ALB, so browsers block those calls as mixed content regardless of the CSP. A working web client needs a real domain (HTTPS on the ALB).

The policy is asserted in `infrastructure/environments/prod/tests/edge.tftest.hcl` for both branches (with and without a domain). The frontend repo asserts the same string against `index.html` (`apps/web-client/index-csp.test.ts`); change both together.

## SPA Routing

When a user navigates directly to a client-side route like `/todos/123`, S3 returns a 403 because that file does not exist. CloudFront is configured to intercept 403 and 404 responses and return `index.html` with a `200` status instead.

The SPA JavaScript then reads the URL and renders the correct view.

## Cache Strategy

Assets are long-lived and content-hashed by the build tool. They never change for a given hash, so they are served with an immutable cache header:

```
Cache-Control: max-age=31536000, immutable
```

`index.html` is the entry point that references the current hashes. It must always be fresh:

```
Cache-Control: no-cache, no-store, must-revalidate
```

This means browsers always fetch the latest `index.html` on each visit, which then pulls the correct versioned assets — no stale bundles.

## Deployment

Triggered on every `v*` tag push. Steps:

1. Build the SPA (`VITE_ASSETS_BASE_URL` is baked in at build time)
2. Upload assets to the assets bucket with immutable headers
3. Upload the build to `releases/<version>/` in the web-client bucket (versioned archive)
4. Sync to the bucket root (active version), overriding `index.html` with no-cache headers
5. Invalidate CloudFront cache
6. Remove old releases, keeping the last 10

```shell
# Active version lives at the root
aws s3 sync apps/web-client/dist s3://<WEB_CLIENT_BUCKET>/ --delete

# Versioned archive is kept for rollback
s3://<WEB_CLIENT_BUCKET>/releases/v1.2.3/
```

## Rollback

Rollback is a manual `workflow_dispatch` in GitHub Actions. It requires specifying a version tag.

Steps:

1. Verify the version exists in `releases/`
2. Sync that version back to the bucket root
3. Override `index.html` with no-cache headers
4. Invalidate CloudFront cache

No infrastructure changes are needed. The previous build is already in S3 — it is simply restored to the active position.

CloudFront invalidation is eventually consistent. After triggering it, edge locations may serve the previous version for up to 60 seconds.

## Terraform Setup

```shell
terraform -chdir=infrastructure/environments/prod apply -target=module.stack.module.frontend
```

Outputs needed for GitHub Actions:

```shell
terraform -chdir=infrastructure/environments/prod output cloudfront_url
terraform -chdir=infrastructure/environments/prod output api_url
terraform -chdir=infrastructure/environments/prod output cloudfront_distribution_id
terraform -chdir=infrastructure/environments/prod output web_client_bucket_name
terraform -chdir=infrastructure/environments/prod output assets_bucket_name
```

Set these as variables or secrets in the frontend GitHub repository.

## GitHub Actions Integration

The frontend CI/CD assumes its own OIDC role (`<project>-<environment>-github-frontend-role`), which only allows the S3 sync and the CloudFront invalidation. No IAM user or long-lived credentials are needed.

The GitHub OIDC module creates the frontend role for the repository set in `frontend_repo` (default `frontend`). Its trust policy accepts only the `repo:prod-forge/frontend:environment:prod` subject, so the deploy job must run in the `prod` GitHub environment.

A dedicated IAM policy grants only what is needed:

- `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, `s3:ListBucket` on both buckets
- `cloudfront:CreateInvalidation` on the distribution

The workflows take the role ARN, the bucket names and the distribution id from GitHub variables filled from `terraform output`; see [Deploy workflow variables](workflow.md#deploy-workflow-variables).

## Advantages

**No servers.** S3 and CloudFront handle availability, durability, and scaling. Nothing to patch, restart, or monitor.

**Global edge caching.** CloudFront serves content from edge locations near the user. Latency is low regardless of where the origin bucket is located.

**Pay per use.** No idle cost. You pay only for storage and traffic, which for most SPAs is negligible.

**Fast deployments.** A deploy is a file sync and a cache flush — typically under a minute. No rolling restarts, no health checks to wait on.

**Instant rollback.** Previous releases are stored as versioned archives in S3. Restoring any of them takes the same time as a normal deploy.

## Limitations

**Cache invalidation delay.** CloudFront invalidation propagates within ~60 seconds but is not instantaneous. The no-cache header on `index.html` and content-hashed asset names minimize the practical impact.

**No server-side rendering.** This setup serves a statically built SPA only. SSR requires Lambda@Edge, CloudFront Functions, or a separate ECS service.

**Build-time configuration.** Environment-specific values like `VITE_ASSETS_BASE_URL` are baked into the build. Changing them requires a new deployment.
