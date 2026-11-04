locals {
  files     = fileset(var.source_dir, "**")
  templates = toset([for f in local.files : f if endswith(f, ".tftpl")])
  plain     = setsubtract(local.files, local.templates)

  # *.tftpl files are rendered with the Cloud Map namespace and uploaded without the suffix.
  rendered = { for f in local.templates : trimsuffix(f, ".tftpl") => templatefile("${var.source_dir}/${f}", { namespace = var.service_namespace }) }
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.project}-${var.environment}-observability-config"
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_object" "plain" {
  for_each = local.plain

  bucket = aws_s3_bucket.this.id
  key    = each.value
  source = "${var.source_dir}/${each.value}"
  # source_hash, not etag: the ETag of a KMS-encrypted object is not its MD5.
  source_hash = filemd5("${var.source_dir}/${each.value}")

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.this]
}

resource "aws_s3_object" "rendered" {
  for_each = local.rendered

  bucket      = aws_s3_bucket.this.id
  key         = each.key
  content     = each.value
  source_hash = md5(each.value)

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.this]
}
