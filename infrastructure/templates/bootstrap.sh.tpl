#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
echo "BOOTSTRAP EXECUTED" > /tmp/bootstrap_ran.txt

SECRET_ID="${secret_id}"
REGION="${region}"
REPOSITORY_URL="${repository_url}"

echo "Using secret: $SECRET_ID"
echo "Region: $REGION"

# Обновляем пакеты
sudo apt update -y && sudo apt upgrade -y

# Need to parse Secrets
sudo apt install -y jq

# Установка AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install

# Устанавливаем зависимости
sudo apt install -y ca-certificates curl gnupg

# Добавляем официальный GPG-ключ Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Добавляем репозиторий Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Обновляем пакеты и устанавливаем Docker
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Добавляем пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker

# Запускаем и включаем Docker в автозагрузку
sudo systemctl enable --now docker

echo "end of script, ready to run Grafana, Loki, Prometheus"
