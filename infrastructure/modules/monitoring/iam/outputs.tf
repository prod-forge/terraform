output "monitoring_ec2_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_instance_profile.name

  # The boot-time sync needs the role policies and attachments in place.
  # An output-level dependency orders creation without deferring the
  # consumer's data sources (a module-level depends_on would).
  depends_on = [
    aws_iam_role_policy.observability_config,
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy_attachment.attach,
  ]
}
