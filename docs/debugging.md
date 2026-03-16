# Debugging and Troubleshooting

<p align="center">
  <img alt="The Debugging and Troubleshooting Problem" src="https://github.com/prod-forge/terraform/blob/main/assets/debugging.png" width="512px" height="768px">
</p>

Debugging is one of the most critical aspects of operating production infrastructure.

When something goes wrong in production, engineers must be able to quickly diagnose the problem and identify the root
cause.

This project demonstrates several common debugging practices used when working with AWS infrastructure and containerized
applications.

## ECS / Fargate Debugging

For debugging running containers in AWS ECS Fargate, the session-manager-plugin must be installed.

[Installation guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-macos-overview.html)

### Inspect ECS Tasks

Check the current task status:

```shell
aws ecs describe-tasks \
  --cluster <CLUSTER_NAME> \
  --tasks <TASK_ARN> \
  --query "tasks[0].containers[*].[name,lastStatus,healthStatus,exitCode]"
```

Expected output:

```shell
[
  [
    "some_name",
    "RUNNING",
    "UNKNOWN",
    null
  ]
]
```

### Execute Commands Inside Container

To open an interactive shell inside the container:

```shell
aws ecs execute-command \
  --cluster <CLUSTER_NAME> \
  --task <TASK_ARN> \
  --container <TASK_CONTAINER> \
  --interactive \
  --command "/bin/sh" \
  --region eu-central-1
```

## RDS, Redis Debugging (OpenVPN)

To debug the RDS database and Redis, we need to get into the private network.

To access these resources securely, a VPN connection can be established.

### Install OpenVPN

Example for macOS:

```shell
brew install openvpn
```

### Generate Certificates

In the infrastructure folder we need to create **vpn-key** subfolder and generate certificate.

Run the following commands inside the certificate directory:

```shell
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.crt -subj "/CN=todo"
openssl genrsa -out server.key 2048
```

Create server certificate:

```shell
openssl req -new -key server.key -out server.csr -config openssl.cnf
```

Sign the certificate:

```shell
openssl x509 -req \
  -in server.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out server.crt \
  -days 825 \
  -sha256 \
  -extfile openssl.cnf \
  -extensions v3_ext
```

As a result, you should have this list of files in the **vpn-key** folder:

<p align="center">
  <img alt="Certificate" src="https://github.com/prod-forge/terraform/blob/main/assets/certificate.png" width="307px" height="406px">
</p>

Verify:

```shell
openssl x509 -in server.crt -text -noout
```

Expected output:

```shell
DNS:vpn.internal.local
```

### Generate Client Certificate

```shell
openssl genrsa -out client1.key 2048
openssl req -new -key client1.key -out client1.csr -subj "/CN=client1"
```

Sign client certificate:

```shell
openssl x509 -req \
  -in client1.csr \
  -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out client1.crt \
  -days 825 \
  -sha256
```

### Generate VPN Client Configuration

After you apply VPN Terraform configuration you can generate VPN Client:

```shell
aws ec2 export-client-vpn-client-configuration \
    --client-vpn-endpoint-id <VPN_ENDPOINT> \
    --output text > client.ovpn
```

Add the client certificate to the configuration file (after </ca> block):

```shell
<cert>
(client1.crt)
</cert>

<key>
(client1.key)
</key>
```

#### Verify VPN Connection

1. Connect to VPN
2. Check network interfaces:

```shell
ifconfig
```

Expected output:

```shell
utun4: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST>
inet 10.200.0.34 --> 10.200.0.33 netmask 0xffffffe0
```

Then resolve RDS through the internal DNS:

```shell
nslookup my-postgres-db.chg8augcmdse.eu-central-1.rds.amazonaws.com 10.0.0.2
```

Expected output:

```shell
Name: my-postgres-db.chg8augcmdse.eu-central-1.rds.amazonaws.com
Address: 10.0.2.27
```

### Connect to RDS or Redis

As a result, we can connect to RDS or Redis through VPN:

<p align="center">
  <img alt="RDS Connection" src="https://github.com/prod-forge/terraform/blob/main/assets/datagrip-connection.png" width="794px" height="669px">
</p>

## EC2 SSH Connection

The first debugging step should always be attempting to connect to the instance using SSH.

If the connection fails:

1. Open AWS Console
2. Navigate to EC2 → Instances
3. Select the instance
4. Open the Connect tab

AWS often shows helpful diagnostics. For example:

```shell
Associated subnet subnet-0626737c9c9d00050 (main-subnet) is not a public subnet.
To use EC2 Instance Connect, your instance must be in a public subnet.
```

This message indicates that the instance is located in a private subnet, which means it cannot be accessed directly from
the internet.

### SSH Setup

You need to generate ssh key in the **infrastructure/ssh** folder:

```shell
ssh-keygen -t rsa -b 4096 -f my-key.pem
chmod 400 my-key.pem
```

If the instance is in a public subnet and port 22 is open in the Security Group, you can connect via SSH.

```shell
ssh -i "ssh/my-key.pem" ubuntu@3.121.226.33
```

The default user for Ubuntu-based EC2 images is:

```text
ubuntu
```

Once connected, useful diagnostic commands include:

Check cloud-init status:

```shell
sudo cloud-init status
```

View initialization logs:

```shell
sudo cat /var/log/cloud-init-output.log
```

Verify installed software:

```shell
which docker
```

Most software on EC2 instances runs under sudo:

```shell
sudo docker -v
```

### Debugging bootstrap.sh

If the instance fails during initialization, the problem may be in the bootstrap script.

To debug bootstrap execution:

Destroy the existing instance and recreate it:

```shell
terraform destroy -target=module.monitoring_ec2.aws_instance.monitoring
terraform apply
```

Check system initialization logs:

```shell
sudo tail -n 100 /var/log/cloud-init-output.log
```

A useful debugging trick is adding a marker to the script:

```shell
echo "BOOTSTRAP EXECUTED" > /tmp/bootstrap_ran.txt
```

Then verify whether the script reached that point:

```shell
cat /tmp/bootstrap_ran.txt
```

If the file exists, the script executed successfully up to that step.

