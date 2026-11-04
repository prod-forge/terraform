resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project}-redis"
  description          = "${var.project} Redis replication group"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  port                 = 6379
  parameter_group_name = "default.redis7"

  num_cache_clusters         = var.num_cache_clusters
  multi_az_enabled           = true
  automatic_failover_enabled = true

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [var.sg_redis_id]

  at_rest_encryption_enabled = true
  kms_key_id                 = var.kms_key_arn
  transit_encryption_enabled = true
  auth_token                 = var.auth_token

  snapshot_retention_limit   = var.snapshot_retention_limit
  snapshot_window            = var.snapshot_window
  maintenance_window         = var.maintenance_window
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = true
}
