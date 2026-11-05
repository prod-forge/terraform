# Offline plan of the whole prod root with mock providers: proves the
# composition wires up without the git-ignored VPN key files and checks the
# per-environment switches. vpn_key_dir points at a directory that never exists.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_iam_openid_connect_provider" {
    defaults = {
      arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
    }
  }

  mock_resource "aws_iam_openid_connect_provider" {
    defaults = {
      arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
    }
  }

  mock_resource "aws_db_instance" {
    defaults = {
      master_user_secret = [{ secret_arn = "arn:aws:secretsmanager:eu-central-1:123456789012:secret:rds-master" }]
    }
  }
}

mock_provider "aws" {
  alias = "us_east_1"
}

variables {
  vpn_key_dir = "does-not-exist"
}

############################
# Negative cases
############################

run "vpn_without_key_files_is_rejected" {
  command = plan

  variables {
    enable_client_vpn = true
  }

  expect_failures = [var.enable_client_vpn]
}

############################
# Positive cases
############################

run "prod_plans_without_vpn_key_files" {
  command = plan

  variables {
    enable_client_vpn = false
  }

  assert {
    condition     = output.web_client_bucket_name == "prod-forge-todolist-prod-web-client"
    error_message = "Names must follow <project>-<environment>-<name>."
  }

  assert {
    condition     = output.assets_bucket_name == "prod-forge-todolist-prod-assets"
    error_message = "Names must follow <project>-<environment>-<name>."
  }
}

# Backend CD reads these names from GitHub repository variables filled from the outputs.
run "prod_outputs_the_names_backend_cd_uses" {
  command = plan

  variables {
    enable_client_vpn = false
  }

  assert {
    condition     = output.ecr_repository_name == "prod-forge-todolist-prod"
    error_message = "ECR repository must be <project>-<environment>."
  }

  assert {
    condition     = output.ecs_cluster_name == "prod-forge-todolist-prod-cluster"
    error_message = "ECS cluster must be <project>-<environment>-cluster."
  }

  assert {
    condition     = output.ecs_service_name == "prod-forge-todolist-prod-service"
    error_message = "ECS service must be <project>-<environment>-service."
  }

  assert {
    condition     = output.ecs_task_definition_family == "prod-forge-todolist-prod-task"
    error_message = "App task family must be <project>-<environment>-task."
  }

  assert {
    condition     = output.ecs_migration_task_definition_family == "prod-forge-todolist-prod-migration-task"
    error_message = "Migration task family must be <project>-<environment>-migration-task."
  }

  assert {
    condition     = output.ecs_log_group_name == "/ecs/prod-forge-todolist-prod"
    error_message = "App log group must be /ecs/<project>-<environment>."
  }

  assert {
    condition     = output.ecs_migration_log_group_name == "/ecs/prod-forge-todolist-prod-task-migration"
    error_message = "Migration log group must be /ecs/<project>-<environment>-task-migration."
  }
}

run "dev_switches_plan_end_to_end" {
  command = plan

  variables {
    environment                 = "dev"
    enable_client_vpn           = false
    enable_waf                  = false
    create_github_oidc_provider = false
    redis_num_cache_clusters    = 1
    service_namespace           = "prod-forge-todolist-dev.local"
    monthly_budget_usd          = 0
  }

  assert {
    condition     = output.web_client_bucket_name == "prod-forge-todolist-dev-web-client"
    error_message = "Dev names must carry the dev environment."
  }
}
