# Monitoring host runs on x86, not Graviton

- **What:** the monitoring host is a `t3.small` in both environments, and its bootstrap is pinned to x86: the AMI comes from the `amd64` Ubuntu SSM parameter and the AWS CLI installer is the `x86_64` build. `AGENTS.md` prefers Graviton where it is cost-effective; a `t4g.small` costs about 20% less.
- **Where:** `infrastructure/modules/monitoring/ec2/main.tf` (AMI parameter), `infrastructure/modules/monitoring/ec2/templates/bootstrap.sh.tpl` (AWS CLI download), `monitoring_instance_type` in `infrastructure/environments/*/terraform.tfvars`.
- **Why deferred:** a new AMI or instance family replaces the host, which drops the Prometheus, Loki and Tempo data kept on its volume. Do it together with another change that replaces the host anyway.
- **What a fix needs:** switch the SSM parameter to `.../arm64/hvm/ebs-gp3/ami-id` and the installer to `awscli-exe-linux-aarch64.zip` (or derive both from the instance architecture), set `monitoring_instance_type = "t4g.small"`, check that every image in `infrastructure/observability/docker-compose.yml` is published for `arm64`, and update the cost tables in `guide/cost.md`.
