output "namespace_name" {
  description = "Private DNS namespace name"
  value       = aws_service_discovery_private_dns_namespace.this.name
}

output "backend_service_arn" {
  description = "Cloud Map service ARN the backend ECS service registers in"
  value       = aws_service_discovery_service.backend.arn
}
