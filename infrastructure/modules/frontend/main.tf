############################################################
# Web Client S3 Bucket
############################################################

resource "aws_s3_bucket" "web_client" {
  bucket = var.web_client_bucket_name

  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "devops"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "web_client" {
  bucket = aws_s3_bucket.web_client.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################################
# Assets S3 Bucket
############################################################

resource "aws_s3_bucket" "assets" {
  bucket = var.assets_bucket_name

  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "devops"
    ManagedBy   = "terraform"
  }
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
  name                              = "${var.project}-web-client-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${var.project}-assets-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

############################################################
# CloudFront Distribution
############################################################

resource "aws_cloudfront_distribution" "web_client" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

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
    cloudfront_default_certificate = true
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "devops"
    ManagedBy   = "terraform"
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
  name = "github-actions-web-client-deploy-policy"

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
  role       = var.github_actions_role_name
  policy_arn = aws_iam_policy.web_client_deploy.arn
}
