locals {
  prefix = "${var.project}-${var.environment}"
  # Multi-AZ and automatic failover need a replica; a single node (dev) runs without them.
  failover = var.num_cache_clusters > 1
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.prefix}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${local.prefix}-redis"
  description          = "${local.prefix} Redis replication group"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  port                 = 6379
  parameter_group_name = "default.redis7"

  num_cache_clusters         = var.num_cache_clusters
  multi_az_enabled           = local.failover
  automatic_failover_enabled = local.failover

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
