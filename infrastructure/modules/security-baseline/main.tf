data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  prefix     = "${var.project}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id
  trail_name = "${local.prefix}-trail"
  # Built from parts: the trail ARN is needed in the key, bucket and topic
  # policies that must exist before the trail is created.
  trail_arn = "arn:aws:cloudtrail:${data.aws_region.current.region}:${local.account_id}:trail/${local.trail_name}"
}

############################
# CloudTrail
############################

resource "aws_kms_key" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  description         = "${local.prefix} CloudTrail logs and notifications"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        # Encrypts log files and publishes to the encrypted SNS topic.
        Sid       = "CloudTrailEncrypt"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = ["kms:GenerateDataKey*", "kms:Decrypt", "kms:DescribeKey"]
        Resource  = "*"
        Condition = {
          StringEquals = { "aws:SourceArn" = local.trail_arn }
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "cloudtrail" {
  #checkov:skip=CKV_AWS_18: CloudTrail already records the management events of this bucket; server access logs would need a separate log target bucket
  #checkov:skip=CKV_AWS_144: single-region stack by design; cross-region replication doubles storage for an audit trail that is also kept by CloudTrail event history
  #checkov:skip=CKV2_AWS_62: nothing consumes object events of the trail bucket
  count = var.enable_cloudtrail ? 1 : 0

  bucket = "${local.prefix}-cloudtrail"
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail[0].arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    id     = "archive-and-expire-trail-logs"
    status = "Enabled"

    filter {}

    transition {
      days          = var.cloudtrail_archive_after_days
      storage_class = "GLACIER_IR"
    }

    expiration {
      days = var.cloudtrail_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.cloudtrail]
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "CloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail[0].arn
        Condition = {
          StringEquals = { "aws:SourceArn" = local.trail_arn }
        }
      },
      {
        Sid       = "CloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail[0].arn}/AWSLogs/${local.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = local.trail_arn
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.cloudtrail[0].arn,
          "${aws_s3_bucket.cloudtrail[0].arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]
}

# CloudTrail announces every delivered log file here; subscribe a SIEM or a
# queue to process them.
resource "aws_sns_topic" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name              = "${local.prefix}-cloudtrail"
  kms_master_key_id = aws_kms_key.cloudtrail[0].arn
}

resource "aws_sns_topic_policy" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  arn = aws_sns_topic.cloudtrail[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "CloudTrailPublish"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.cloudtrail[0].arn
        Condition = {
          StringEquals = { "aws:SourceArn" = local.trail_arn }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "this" {
  #checkov:skip=CKV2_AWS_10: the trail is delivered to the KMS-encrypted S3 bucket with log file validation; there are no CloudWatch metric filters or alarms on API calls yet, so a log group would only add ingestion cost
  count = var.enable_cloudtrail ? 1 : 0

  name                          = local.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail[0].id
  kms_key_id                    = aws_kms_key.cloudtrail[0].arn
  sns_topic_name                = aws_sns_topic.cloudtrail[0].arn
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_sns_topic_policy.cloudtrail,
  ]
}

############################
# GuardDuty
############################

# One detector per account and region; findings appear in the GuardDuty console.
resource "aws_guardduty_detector" "this" {
  #checkov:skip=CKV2_AWS_3: a single account without AWS Organizations; the detector is enabled in the region the stack runs in, there is no delegated administrator to configure
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

############################
# IAM Access Analyzer
############################

# Reports resources (S3, KMS, IAM roles, secrets, ...) shared outside the account.
resource "aws_accessanalyzer_analyzer" "this" {
  count = var.enable_access_analyzer ? 1 : 0

  analyzer_name = "${local.prefix}-access-analyzer"
  type          = "ACCOUNT"
}
