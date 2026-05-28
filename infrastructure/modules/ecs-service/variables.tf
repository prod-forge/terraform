variable "ecs_cluster_id" {
  description = "ECS Cluster ID"
  type        = string
}

variable "ecs_task_definition_arn" {
  description = "ECS Task Definition ARN"
  type        = string
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs"
}

variable "sg_ecs_id" {
  type        = string
  description = "Security Group for ECS ID"
}

variable "lb_target_group_arn" {
  type        = string
  description = "Load Balancer Target Group ARN"
}

variable "project" {
  description = "Project Name"
  type        = string
}

variable "github_actions_role_name" {
  description = "IAM role name for GitHub Actions to attach ECS deploy policy"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}
