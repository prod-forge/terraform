variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "owner" {
  description = "Owner tag"
  type        = string
}

variable "cost_center" {
  description = "CostCenter tag"
  type        = string
}

variable "repository" {
  description = "Repository tag"
  type        = string
}
