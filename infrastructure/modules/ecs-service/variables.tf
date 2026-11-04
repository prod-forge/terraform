variable "ecs_cluster_id" {
  description = "ECS Cluster ID"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS Cluster name"
  type        = string
}

variable "ecs_task_definition_arn" {
  description = "ECS Task Definition ARN"
  type        = string
}

variable "task_definition_family" {
  description = "Family of the application task definition, used to scope the CD policy"
  type        = string
}

variable "migration_task_definition_family" {
  description = "Family of the one-off migration task definition registered by the backend CD"
  type        = string
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the service tasks"
}

variable "sg_ecs_id" {
  type        = string
  description = "Security Group for ECS ID"
}

variable "lb_target_group_arn" {
  type        = string
  description = "Load Balancer Target Group ARN"
}

variable "lb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix, used by the ALBRequestCountPerTarget scaling metric"
}

variable "lb_target_group_arn_suffix" {
  type        = string
  description = "Target group ARN suffix, used by the ALBRequestCountPerTarget scaling metric"
}

variable "project" {
  description = "Project Name"
  type        = string
}

variable "backend_role_name" {
  description = "Backend GitHub Actions role that receives the ECS deploy policy"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "desired_count" {
  description = "Initial number of tasks; afterwards Application Auto Scaling owns it"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum number of tasks kept by auto scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks auto scaling may run"
  type        = number
  default     = 2
}

variable "cpu_target_value" {
  description = "Target average CPU utilization (percent) for the service"
  type        = number
  default     = 60
}

variable "requests_per_target_value" {
  description = "Target ALB request count per task per minute"
  type        = number
  default     = 1000
}

variable "service_discovery_arn" {
  description = "Cloud Map service ARN to register tasks in; null disables service discovery"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (dev, prod), used in resource names"
  type        = string
}

variable "task_role_arns" {
  description = "Task and task execution role ARNs the backend CD may pass to ECS"
  type        = list(string)
}
