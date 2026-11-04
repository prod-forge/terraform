output "cloudfront_url" {
  value = local.custom_domain ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.web_client.domain_name}"
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.web_client.id
}

output "web_client_bucket_name" {
  value = aws_s3_bucket.web_client.bucket
}

output "assets_bucket_name" {
  value = aws_s3_bucket.assets.bucket
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.web_client.domain_name
}

output "cloudfront_hosted_zone_id" {
  value = aws_cloudfront_distribution.web_client.hosted_zone_id
}
