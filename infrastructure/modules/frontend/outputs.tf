output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.web_client.domain_name}"
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
