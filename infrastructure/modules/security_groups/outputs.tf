output "sg_alb_id" {
  value = aws_security_group.alb_sg.id
}

output "sg_ecs_id" {
  value = aws_security_group.ecs_sg.id
}

output "sg_rds_id" {
  value = aws_security_group.rds_sg.id
}

output "sg_vpn_id" {
  value = aws_security_group.vpn_sg.id
}

output "sg_redis_id" {
  value = aws_security_group.redis_sg.id
}
