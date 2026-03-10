resource "aws_instance" "monitoring" {
  ami           = "ami-03250b0e01c28d196"
  instance_type = "t2.micro"
  tags = {
    Name = "Monitoring"
  }
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true

  user_data = templatefile("templates/bootstrap.sh.tpl", {
    repository_url = var.repository_url
    secret_id      = "prod/app/config-v2"
    region         = "eu-central-1"
  })
  user_data_replace_on_change = true
  key_name                    = var.key_pair_key_name
  # Очень важно установить Security Group чтобы открыть порты в instance для SSH, и для того чтобы зайти на сервер по IP
  vpc_security_group_ids = [var.sg_monitoring_id]
  # Connect EC2 to ECR, Secret Manager
  iam_instance_profile = var.monitoring_ec2_instance_profile_name
}
