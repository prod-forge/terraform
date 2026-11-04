# Offline plan-only tests for the account security baseline (CloudTrail,
# GuardDuty, IAM Access Analyzer).

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-central-1"
    }
  }
}

variables {
  project     = "prod-forge-test"
  environment = "prod"
}

############################
# Negative cases
############################

run "rejects_retention_shorter_than_archive" {
  command = plan

  module {
    source = "../../modules/security-baseline"
  }

  variables {
    cloudtrail_archive_after_days = 90
    cloudtrail_retention_days     = 60
  }

  expect_failures = [var.cloudtrail_retention_days]
}

############################
# Positive cases
############################

run "disabled_services_create_nothing" {
  command = plan

  module {
    source = "../../modules/security-baseline"
  }

  variables {
    enable_cloudtrail      = false
    enable_guardduty       = false
    enable_access_analyzer = false
  }

  assert {
    condition = (
      length(aws_cloudtrail.this) == 0 &&
      length(aws_s3_bucket.cloudtrail) == 0 &&
      length(aws_kms_key.cloudtrail) == 0 &&
      length(aws_guardduty_detector.this) == 0 &&
      length(aws_accessanalyzer_analyzer.this) == 0
    )
    error_message = "With every switch off the module must create nothing."
  }
}

run "trail_is_multi_region_encrypted_and_validated" {
  command = plan

  module {
    source = "../../modules/security-baseline"
  }

  assert {
    condition = (
      aws_cloudtrail.this[0].is_multi_region_trail &&
      aws_cloudtrail.this[0].include_global_service_events &&
      aws_cloudtrail.this[0].enable_log_file_validation
    )
    error_message = "The trail must cover every region and global services and validate log files."
  }

  assert {
    condition     = aws_cloudtrail.this[0].name == "prod-forge-test-prod-trail" && aws_s3_bucket.cloudtrail[0].bucket == "prod-forge-test-prod-cloudtrail"
    error_message = "Trail and bucket names must follow <project>-<environment>-<name>."
  }

  assert {
    condition     = aws_kms_key.cloudtrail[0].enable_key_rotation
    error_message = "The CloudTrail key must rotate."
  }

  assert {
    condition = (
      one(aws_s3_bucket_lifecycle_configuration.cloudtrail[0].rule[0].transition).days == 90 &&
      one(aws_s3_bucket_lifecycle_configuration.cloudtrail[0].rule[0].expiration).days == 365
    )
    error_message = "Trail logs must move to Glacier IR after 90 days and expire after 365."
  }
}

run "guardduty_and_access_analyzer_are_enabled" {
  command = plan

  module {
    source = "../../modules/security-baseline"
  }

  assert {
    condition     = aws_guardduty_detector.this[0].enable && aws_guardduty_detector.this[0].finding_publishing_frequency == "FIFTEEN_MINUTES"
    error_message = "GuardDuty must be enabled and publish findings every 15 minutes."
  }

  assert {
    condition     = aws_accessanalyzer_analyzer.this[0].type == "ACCOUNT" && aws_accessanalyzer_analyzer.this[0].analyzer_name == "prod-forge-test-prod-access-analyzer"
    error_message = "An account-level analyzer named <project>-<environment>-access-analyzer must exist."
  }
}
