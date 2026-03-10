variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "monitoring_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "monitoring_egress_from_port" {
  description = "Начальный порт для исходящего трафика"
  type        = number
}

variable "monitoring_egress_to_port" {
  description = "Конечный порт для исходящего трафика"
  type        = number
}

variable "monitoring_egress_protocol" {
  description = "Протокол для исходящего трафика"
  type        = string
}

variable "monitoring_egress_cidr_blocks" {
  description = "Список CIDR блоков для исходящего трафика"
  type        = list(string)
}
