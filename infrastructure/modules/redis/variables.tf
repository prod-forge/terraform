variable "sg_redis_id" {
  description = "SG Redis ID"
  type        = string
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "project" {
  description = "Project Name"
  type        = string
}
