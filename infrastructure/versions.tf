terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.35"
    }
  }

  backend "s3" {
    bucket         = "prod-forge-todolist-terraform-state-prod"
    key            = "infrastructure/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "prod-forge-todolist-terraform-locks-prod"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
