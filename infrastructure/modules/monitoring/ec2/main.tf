# Latest Canonical Ubuntu 24.04 LTS AMI, resolved at plan time.
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_instance" "monitoring" {
  #checkov:skip=CKV_AWS_88: the public IP exists only for egress (SSM, package and image downloads) from a public subnet; there is no SSH and no inbound path except Grafana from the optional var.admin_cidr_blocks

  ami           = data.aws_ssm_parameter.ubuntu.value
  instance_type = var.instance_type
  tags = {
    Name = "${var.project}-${var.environment}-monitoring"
  }
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  monitoring                  = true
  ebs_optimized               = true

  user_data = templatefile("${path.module}/templates/bootstrap.sh.tpl", {
    region         = var.region
    bucket         = var.observability_bucket
    grafana_secret = var.grafana_admin_secret_arn
  })
  user_data_replace_on_change = true

  # No key pair: the host is reached only through SSM Session Manager.
  # The security group controls which ports (Grafana) are reachable by IP.
  vpc_security_group_ids = [var.sg_monitoring_id]
  # Grants Secrets Manager (Grafana password), S3 config and SSM
  iam_instance_profile = var.monitoring_ec2_instance_profile_name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 30
  }

  # AMI updates are rolled out deliberately (taint/replace), not on every
  # SSM parameter change.
  lifecycle {
    ignore_changes = [ami]
  }
}
