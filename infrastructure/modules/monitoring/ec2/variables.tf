variable "repository_url" {
  description = "ECR URL"
  type        = string
}

variable "key_pair_key_name" {
  description = "Key Pair Key Name"
  type        = string
}

variable "sg_monitoring_id" {
  description = "Security Group Monitoring ID"
  type        = string
}

variable "monitoring_ec2_instance_profile_name" {
  description = "IAM Monitoring Instance Profile Name"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID"
  type        = string
}
