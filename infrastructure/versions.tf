terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.35"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  backend "s3" {
    bucket       = "prod-forge-todolist-terraform-state-prod"
    key          = "infrastructure/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.region
}

# CloudFront certificates and CLOUDFRONT-scope WAF ACLs exist only in us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
