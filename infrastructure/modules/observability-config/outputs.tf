output "bucket_name" {
  description = "Observability config bucket name"
  value       = aws_s3_bucket.this.bucket

  # Consumers sync the files at boot: the objects must exist first.
  depends_on = [aws_s3_object.plain, aws_s3_object.rendered]
}

output "bucket_arn" {
  description = "Observability config bucket ARN"
  value       = aws_s3_bucket.this.arn
}
