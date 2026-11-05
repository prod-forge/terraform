locals {
  custom_domain = var.domain_name != ""

  # Same policy as the web client index.html meta tag (frontend guide/security.md).
  # The assets are served by this distribution under /assets, so 'self' covers them.
  # 'unsafe-inline' for styles: see the frontend security chapter.
  content_security_policy = join("; ", [
    "default-src 'self'",
    "script-src 'self'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: https:",
    "connect-src 'self' ${var.api_origin} https://*.sentry.io",
    "font-src 'self' data:",
    "worker-src 'self' blob:",
    "object-src 'none'",
    "base-uri 'self'",
    "frame-ancestors 'none'",
  ])
}

############################################################
# Web Client S3 Bucket
############################################################

resource "aws_s3_bucket" "web_client" {
  bucket = var.web_client_bucket_name
}

resource "aws_s3_bucket_public_access_block" "web_client" {
  bucket = aws_s3_bucket.web_client.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning keeps the previous build recoverable after a bad deploy.
resource "aws_s3_bucket_versioning" "web_client" {
  bucket = aws_s3_bucket.web_client.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "web_client" {
  bucket = aws_s3_bucket.web_client.id

  rule {
    id     = "expire-noncurrent-builds"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.web_client]
}

############################################################
# Assets S3 Bucket
############################################################

resource "aws_s3_bucket" "assets" {
  bucket = var.assets_bucket_name
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################################
# CloudFront Origin Access Controls
############################################################

resource "aws_cloudfront_origin_access_control" "web_client" {
  name                              = "${var.project}-${var.environment}-web-client-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${var.project}-${var.environment}-assets-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

############################################################
# CloudFront Security Response Headers
############################################################

# The header is the enforced Content-Security-Policy. The index.html meta tag
# carries the same policy as a fallback for local development, and the meta tag
# cannot carry frame-ancestors.
resource "aws_cloudfront_response_headers_policy" "security" {
  #checkov:skip=CKV_AWS_259: HSTS preload is a hard-to-revert commitment for the whole domain; it stays off until the owner opts in
  name = "${var.project}-${var.environment}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = false
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    content_security_policy {
      content_security_policy = local.content_security_policy
      override                = true
    }
  }
}

############################################################
# CloudFront Distribution
############################################################

resource "aws_cloudfront_distribution" "web_client" {
  #checkov:skip=CKV_AWS_310: both origins are single-region S3 buckets; a failover origin needs a replicated bucket that is not provisioned
  #checkov:skip=CKV_AWS_374: the web client is public for every country; geo blocking has no business requirement
  #checkov:skip=CKV_AWS_174: TLS 1.2 is enforced whenever a custom domain is set; the default *.cloudfront.net certificate only allows TLSv1
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  aliases             = local.custom_domain ? [var.domain_name] : []
  web_acl_id          = var.web_acl_arn

  logging_config {
    bucket          = var.logs_bucket_domain_name
    prefix          = "${var.logs_prefix}/"
    include_cookies = false
  }

  origin {
    domain_name              = aws_s3_bucket.web_client.bucket_regional_domain_name
    origin_id                = "web-client"
    origin_access_control_id = aws_cloudfront_origin_access_control.web_client.id
  }

  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = "assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "web-client"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    # AWS managed CachingOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "assets"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    # AWS managed CachingOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # SPA routing: unknown paths return index.html
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = !local.custom_domain
    acm_certificate_arn            = local.custom_domain ? var.acm_certificate_arn : null
    ssl_support_method             = local.custom_domain ? "sni-only" : null
    minimum_protocol_version       = local.custom_domain ? "TLSv1.2_2021" : "TLSv1"
  }
}

############################################################
# S3 Bucket Policies (allow CloudFront OAC)
############################################################

resource "aws_s3_bucket_policy" "web_client" {
  bucket = aws_s3_bucket.web_client.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.web_client.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.web_client.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.assets.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.web_client.arn
          }
        }
      }
    ]
  })
}

############################################################
# GitHub Actions Deploy Policy
############################################################

resource "aws_iam_policy" "web_client_deploy" {
  name = "${var.project}-${var.environment}-github-web-client-deploy-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.web_client.arn,
          "${aws_s3_bucket.web_client.arn}/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.assets.arn,
          "${aws_s3_bucket.assets.arn}/*",
        ]
      },
      {
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = aws_cloudfront_distribution.web_client.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "web_client_deploy" {
  role       = var.frontend_role_name
  policy_arn = aws_iam_policy.web_client_deploy.arn
}
