# Offline plan-only tests for the network and data protection settings that
# Checkov enforces (default security group, KMS key policy, RDS TLS). Each run
# targets a module directly because module.stack declares configuration_aliases
# and cannot be the module of a run block (guide/ci.md).

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
    }
  }
}

mock_provider "random" {}

variables {
  project     = "prod-forge-test"
  environment = "prod"
}

############################
# Positive cases
############################

run "vpc_default_security_group_has_no_rules" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  override_resource {
    target          = aws_vpc.this
    override_during = plan
    values = {
      id = "vpc-0123456789abcdef0"
    }
  }

  # ingress and egress are optional and computed: the override fills them only when the
  # module declares no rules, so a rule added in the module makes the assertion fail.
  override_resource {
    target          = aws_default_security_group.this
    override_during = plan
    values = {
      ingress = []
      egress  = []
    }
  }

  assert {
    condition     = aws_default_security_group.this.vpc_id == aws_vpc.this.id
    error_message = "The default security group of the VPC must be managed."
  }

  assert {
    condition     = length(aws_default_security_group.this.ingress) == 0 && length(aws_default_security_group.this.egress) == 0
    error_message = "The default security group must have no ingress or egress rules."
  }
}

run "secrets_kms_key_policy_grants_only_the_account" {
  command = plan

  module {
    source = "../../modules/secrets_manager"
  }

  variables {
    secrets_manager_name = "prod_forge/backend/prod/config-v1"
  }

  assert {
    condition     = aws_kms_key.this.enable_key_rotation
    error_message = "The secrets KMS key must rotate."
  }

  assert {
    condition = jsondecode(aws_kms_key.this.policy).Statement == [
      {
        Sid       = "EnableIamUserPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::123456789012:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
    ]
    error_message = "The key policy must have exactly the account root statement."
  }
}

run "rds_parameter_group_forces_ssl" {
  command = plan

  module {
    source = "../../modules/rds"
  }

  variables {
    db_subnet_group_name  = "prod-forge-test-db-subnets"
    vpc_security_group_id = "sg-0123456789abcdef0"
    username              = "prod_forge"
    db_name               = "prod_forge"
    rds_identifier        = "prod-forge-test-db"
    kms_key_arn           = "arn:aws:kms:eu-central-1:123456789012:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition = [
      for p in aws_db_parameter_group.postgres.parameter : p.value
      if p.name == "rds.force_ssl"
    ] == ["1"]
    error_message = "The parameter group must set rds.force_ssl = 1."
  }
}
