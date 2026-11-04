output "bucket_name" {
  description = "Observability config bucket name"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "Observability config bucket ARN"
  value       = aws_s3_bucket.this.arn
}
