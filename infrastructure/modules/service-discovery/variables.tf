variable "project" {
  description = "Project name, used in the namespace description"
  type        = string
}

variable "vpc_id" {
  description = "VPC the private DNS namespace is attached to"
  type        = string
}

variable "namespace_name" {
  description = "Private DNS namespace name, unique per environment (for example <project>.local in prod, <project>-dev.local in dev)"
  type        = string
}
