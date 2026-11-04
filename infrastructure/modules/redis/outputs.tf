output "redis_host" {
  description = "Primary endpoint address"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.redis.port
}

output "replication_group_id" {
  description = "Replication group ID"
  value       = aws_elasticache_replication_group.redis.replication_group_id
}

output "num_cache_clusters" {
  description = "Number of nodes (primary plus replicas)"
  value       = var.num_cache_clusters
}
