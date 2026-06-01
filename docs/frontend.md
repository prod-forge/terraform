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
terraform apply -target=module.frontend
```

Outputs needed for GitHub Actions:

```shell
terraform output cloudfront_url
terraform output cloudfront_distribution_id
terraform output web_client_bucket_name
terraform output assets_bucket_name
```

Set these as variables or secrets in the frontend GitHub repository.

## GitHub Actions Integration

The frontend CI/CD reuses the same OIDC role configured for the backend. No separate IAM user or additional credentials are needed.

The GitHub OIDC module already trusts the `frontend` repository:

```hcl
github_repos = ["backend", "frontend"]
```

A dedicated IAM policy grants only what is needed:

- `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, `s3:ListBucket` on both buckets
- `cloudfront:CreateInvalidation` on the distribution

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
