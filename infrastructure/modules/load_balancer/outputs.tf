output "lb_target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "lb_listener" {
  description = "Listener that forwards to the target group (443 with a domain, otherwise 80)"
  value       = local.https_enabled ? aws_lb_listener.https[0] : aws_lb_listener.app
}

output "lb_arn" {
  value = aws_lb.app.arn
}

output "lb_arn_suffix" {
  value = aws_lb.app.arn_suffix
}

output "lb_dns_name" {
  value = aws_lb.app.dns_name
}

output "lb_zone_id" {
  value = aws_lb.app.zone_id
}

output "lb_target_group_arn_suffix" {
  value = aws_lb_target_group.app.arn_suffix
}
