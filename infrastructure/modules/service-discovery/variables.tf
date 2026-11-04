variable "project" {
  description = "Project name; the private DNS namespace is <project>.local"
  type        = string
}

variable "vpc_id" {
  description = "VPC the private DNS namespace is attached to"
  type        = string
}
