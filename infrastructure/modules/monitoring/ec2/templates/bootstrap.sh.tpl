#!/bin/bash
# Bootstraps the monitoring host (Ubuntu 24.04): Docker, AWS CLI, the
# observability stack synced from S3 and a systemd unit that keeps it running.
# Safe to run more than once.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

exec > >(tee -a /var/log/bootstrap.log) 2>&1

echo "Bootstrap started: bucket=${bucket} region=${region}"

apt-get update -y
apt-get install -y ca-certificates curl gnupg jq unzip

# AWS CLI v2 (Ubuntu 24.04 has no apt package for it)
if ! command -v aws > /dev/null; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q -o /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

# Docker Engine with the compose plugin from Docker's official repository
if ! command -v docker > /dev/null || ! docker compose version > /dev/null 2>&1; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  # shellcheck source=/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi
systemctl enable --now docker

# Sync script, also used to roll out changed configuration (see docs/observability.md)
cat > /usr/local/bin/observability-sync << 'SYNC'
#!/bin/bash
set -euo pipefail
export AWS_DEFAULT_REGION="${region}"
STACK_DIR="/opt/observability"

mkdir -p "$STACK_DIR"
aws s3 sync "s3://${bucket}" "$STACK_DIR" --delete --exclude ".env"

PASSWORD="$(aws secretsmanager get-secret-value --secret-id "${grafana_secret}" --query SecretString --output text)"
umask 077
printf 'GRAFANA_ADMIN_PASSWORD=%s\n' "$PASSWORD" > "$STACK_DIR/.env"

cd "$STACK_DIR"
docker compose up -d --remove-orphans
SYNC
chmod 0755 /usr/local/bin/observability-sync

cat > /etc/systemd/system/observability.service << 'UNIT'
[Unit]
Description=Observability stack (Prometheus, Grafana, Loki, Promtail, Tempo)
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/observability
ExecStart=/usr/bin/docker compose up -d --remove-orphans
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable observability.service

/usr/local/bin/observability-sync

echo "Bootstrap finished: observability stack is running from /opt/observability"
