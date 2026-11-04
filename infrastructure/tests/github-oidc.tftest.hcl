# Offline plan-only test: each GitHub Actions role must trust only its own repository.

mock_provider "aws" {}

# The provider ARN is computed; pin it so the trust policy is known at plan time.
override_resource {
  target          = aws_iam_openid_connect_provider.github
  override_during = plan
  values = {
    arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  }
}

variables {
  project      = "prod-forge-test"
  environment  = "dev"
  github_owner = "prod-forge"
}

run "backend_role_trusts_only_backend_repo" {
  command = plan

  module {
    source = "./modules/github-oidc"
  }

  assert {
    condition = alltrue([
      for sub in jsondecode(aws_iam_role.github["backend"].assume_role_policy).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"] :
      startswith(sub, "repo:prod-forge/backend:")
    ])
    error_message = "Backend role must only trust repo:prod-forge/backend"
  }

  assert {
    condition = toset(jsondecode(aws_iam_role.github["backend"].assume_role_policy).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"]) == toset([
      "repo:prod-forge/backend:environment:prod",
      "repo:prod-forge/backend:ref:refs/tags/v*",
    ])
    error_message = "Backend role must trust exactly the prod environment and release tags"
  }

  assert {
    condition     = jsondecode(aws_iam_role.github["backend"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com"
    error_message = "Backend role must require the sts.amazonaws.com audience"
  }

  assert {
    condition     = aws_iam_role.github["backend"].name == "prod-forge-test-dev-github-backend-role"
    error_message = "Backend role name must follow <project>-<environment>-github-backend-role"
  }
}

run "frontend_role_trusts_only_frontend_repo" {
  command = plan

  module {
    source = "./modules/github-oidc"
  }

  assert {
    condition = alltrue([
      for sub in jsondecode(aws_iam_role.github["frontend"].assume_role_policy).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"] :
      startswith(sub, "repo:prod-forge/frontend:")
    ])
    error_message = "Frontend role must only trust repo:prod-forge/frontend"
  }

  assert {
    condition = toset(jsondecode(aws_iam_role.github["frontend"].assume_role_policy).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"]) == toset([
      "repo:prod-forge/frontend:environment:prod",
      "repo:prod-forge/frontend:ref:refs/tags/v*",
    ])
    error_message = "Frontend role must trust exactly the prod environment and release tags"
  }

  assert {
    condition     = jsondecode(aws_iam_role.github["frontend"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"] == "sts.amazonaws.com"
    error_message = "Frontend role must require the sts.amazonaws.com audience"
  }
}
