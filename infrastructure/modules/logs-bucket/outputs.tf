# Consumers validate write access when logging is enabled, so the outputs wait
# for the bucket policy (ALB) and the ownership controls (CloudFront ACL grant).
output "bucket_name" {
  value      = aws_s3_bucket.logs.bucket
  depends_on = [aws_s3_bucket_policy.logs]
}

output "bucket_domain_name" {
  description = "Bucket domain name, the format CloudFront standard logging expects"
  value       = aws_s3_bucket.logs.bucket_domain_name
  depends_on  = [aws_s3_bucket_ownership_controls.logs]
}

output "alb_prefix" {
  value = var.alb_prefix
}

output "cloudfront_prefix" {
  value = var.cloudfront_prefix
}
