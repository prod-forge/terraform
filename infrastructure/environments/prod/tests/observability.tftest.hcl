# Offline plan-only tests for the observability config bucket and Cloud Map
# namespace. Each run targets a module directly because the root reads
# git-ignored VPN key files with file(), which do not exist in CI.

mock_provider "aws" {}

variables {
  project     = "prod-forge-test"
  environment = "dev"
}

run "every_observability_file_is_uploaded" {
  command = plan

  module {
    source = "../../modules/observability-config"
  }

  variables {
    source_dir        = "../../observability"
    service_namespace = "prod-forge-test.local"
    kms_key_arn       = "arn:aws:kms:eu-central-1:123456789012:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(aws_s3_object.plain) + length(aws_s3_object.rendered) == length(fileset("../../observability", "**"))
    error_message = "Every file under observability/ must become one S3 object."
  }

  assert {
    condition     = contains(keys(aws_s3_object.rendered), "prometheus/prometheus.yml")
    error_message = "The Prometheus template must be uploaded without the .tftpl suffix."
  }

  assert {
    condition     = strcontains(aws_s3_object.rendered["prometheus/prometheus.yml"].content, "backend.prod-forge-test.local")
    error_message = "The Prometheus scrape target must use the project namespace."
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "prod-forge-test-dev-observability-config"
    error_message = "Bucket name must be <project>-<environment>-observability-config."
  }
}

run "service_discovery_namespace_is_project_local" {
  command = plan

  module {
    source = "../../modules/service-discovery"
  }

  variables {
    vpc_id         = "vpc-0123456789abcdef0"
    namespace_name = "prod-forge-test.local"
  }

  assert {
    condition     = aws_service_discovery_private_dns_namespace.this.name == "prod-forge-test.local"
    error_message = "Namespace must be <project>.local."
  }

  assert {
    condition     = aws_service_discovery_service.backend.name == "backend"
    error_message = "The Cloud Map service must be called backend."
  }

  assert {
    condition     = one(aws_service_discovery_service.backend.dns_config[0].dns_records).ttl == 10
    error_message = "A records must use a 10 second TTL."
  }
}
