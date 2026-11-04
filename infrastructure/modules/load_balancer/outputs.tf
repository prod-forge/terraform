output "lb_target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "lb_listener" {
  value = aws_lb_listener.app
}

output "lb_arn_suffix" {
  value = aws_lb.app.arn_suffix
}

output "lb_target_group_arn_suffix" {
  value = aws_lb_target_group.app.arn_suffix
}
