# Offline plan-only tests for the conditional edge logic (certificates, HTTPS,
# DNS, WAF, CloudFront). Each run targets a module directly because the root
# reads git-ignored VPN key files with file(), which do not exist in CI.

mock_provider "aws" {
  mock_data "aws_route53_zone" {
    defaults = {
      zone_id = "Z0000000000000EXAMPLE"
    }
  }
}

variables {
  project     = "prod-forge-test"
  environment = "dev"

  vpc_id             = "vpc-0123456789abcdef0"
  sg_alb_id          = "sg-0123456789abcdef0"
  public_subnet_ids  = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  access_logs_bucket = "prod-forge-test-access-logs"

  web_client_bucket_name  = "prod-forge-test-web-client"
  assets_bucket_name      = "prod-forge-test-assets"
  frontend_role_name      = "github-frontend"
  web_acl_arn             = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/test/00000000-0000-0000-0000-000000000000"
  logs_bucket_domain_name = "prod-forge-test-access-logs.s3.amazonaws.com"

  alb_dns_name           = "test-alb-123456789.eu-central-1.elb.amazonaws.com"
  alb_zone_id            = "Z215JYRZR1TBD5"
  cloudfront_domain_name = "d111111abcdef8.cloudfront.net"
  cloudfront_zone_id     = "Z2FDTNDATAQYW2"
}

############################
# Negative cases
############################

run "acm_certificate_rejects_domain_without_zone" {
  command = plan

  module {
    source = "../../modules/acm-certificate"
  }

  variables {
    domain_name = "example.com"
  }

  expect_failures = [var.hosted_zone_id]
}

run "load_balancer_rejects_domain_without_certificate" {
  command = plan

  module {
    source = "../../modules/load_balancer"
  }

  variables {
    domain_name = "api.example.com"
  }

  expect_failures = [var.certificate_arn]
}

run "frontend_rejects_domain_without_certificate" {
  command = plan

  module {
    source = "../../modules/frontend"
  }

  variables {
    domain_name = "example.com"
  }

  expect_failures = [var.acm_certificate_arn]
}

run "dns_rejects_domain_without_zone_name" {
  command = plan

  module {
    source = "../../modules/dns"
  }

  variables {
    domain_name = "example.com"
  }

  expect_failures = [var.hosted_zone_name]
}

run "waf_rejects_unknown_scope" {
  command = plan

  module {
    source = "../../modules/waf"
  }

  variables {
    scope = "GLOBAL"
  }

  expect_failures = [var.scope]
}

run "waf_rejects_regional_scope_without_resource" {
  command = plan

  module {
    source = "../../modules/waf"
  }

  variables {
    scope = "REGIONAL"
  }

  expect_failures = [var.resource_arn]
}

############################
# Positive cases: no domain
############################

run "acm_certificate_without_domain_creates_nothing" {
  command = plan

  module {
    source = "../../modules/acm-certificate"
  }

  assert {
    condition = (
      length(aws_acm_certificate.this) == 0 &&
      length(aws_route53_record.validation) == 0 &&
      length(aws_acm_certificate_validation.this) == 0
    )
    error_message = "No certificate or validation record may be created without a domain."
  }

  assert {
    condition     = output.certificate_arn == ""
    error_message = "certificate_arn must be empty without a domain."
  }
}

run "load_balancer_without_domain_forwards_http" {
  command = plan

  module {
    source = "../../modules/load_balancer"
  }

  assert {
    condition     = length(aws_lb_listener.https) == 0
    error_message = "No 443 listener may be created without a domain."
  }

  assert {
    condition     = aws_lb_listener.app.default_action[0].type == "forward"
    error_message = "Port 80 must forward to the target group without a domain."
  }

  assert {
    condition = (
      one([for c in aws_lb_listener_rule.block_metrics.condition : one(c.path_pattern).values]) == toset(["/metrics*", "/api/metrics*"]) &&
      aws_lb_listener_rule.block_metrics.action[0].fixed_response[0].status_code == "404"
    )
    error_message = "/metrics* and /api/metrics* must return 404 on the port 80 listener."
  }

  assert {
    condition     = aws_lb_target_group.app.deregistration_delay == "30"
    error_message = "The target group must drain for 30 s."
  }

  assert {
    condition     = aws_lb.app.enable_deletion_protection == false
    error_message = "Deletion protection must be off outside prod."
  }

  assert {
    condition     = aws_lb.app.drop_invalid_header_fields && aws_lb.app.access_logs[0].enabled
    error_message = "The ALB must drop invalid headers and write access logs."
  }
}

run "dns_without_domain_creates_nothing" {
  command = plan

  module {
    source = "../../modules/dns"
  }

  assert {
    condition     = length(data.aws_route53_zone.this) == 0
    error_message = "The hosted zone must not be looked up without a domain."
  }

  assert {
    condition     = length(aws_route53_record.api) == 0 && length(aws_route53_record.web) == 0
    error_message = "No DNS records may be created without a domain."
  }

  assert {
    condition     = output.zone_id == ""
    error_message = "zone_id must be empty without a domain."
  }
}

run "frontend_without_domain_uses_default_certificate" {
  command = plan

  module {
    source = "../../modules/frontend"
  }

  assert {
    condition     = length(aws_cloudfront_distribution.web_client.aliases) == 0
    error_message = "The distribution must have no aliases without a domain."
  }

  assert {
    condition     = aws_cloudfront_distribution.web_client.viewer_certificate[0].cloudfront_default_certificate
    error_message = "The default CloudFront certificate must be used without a domain."
  }

  assert {
    condition     = aws_cloudfront_distribution.web_client.web_acl_id == var.web_acl_arn
    error_message = "The CloudFront WAF ACL must be attached."
  }

  assert {
    condition     = aws_cloudfront_distribution.web_client.logging_config[0].prefix == "cloudfront/"
    error_message = "CloudFront standard logging must write under cloudfront/."
  }

  assert {
    condition     = aws_s3_bucket_versioning.web_client.versioning_configuration[0].status == "Enabled"
    error_message = "The web client bucket must be versioned."
  }

  assert {
    condition     = one(aws_s3_bucket_lifecycle_configuration.web_client.rule[0].noncurrent_version_expiration).noncurrent_days == 30
    error_message = "Previous web client builds must expire after 30 days."
  }
}

run "waf_regional_acl_is_associated" {
  command = plan

  module {
    source = "../../modules/waf"
  }

  variables {
    scope        = "REGIONAL"
    resource_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:loadbalancer/app/test/0123456789abcdef"
  }

  assert {
    condition     = length(aws_wafv2_web_acl_association.this) == 1
    error_message = "The regional ACL must have exactly one association."
  }

  assert {
    condition     = aws_wafv2_web_acl_association.this[0].resource_arn == var.resource_arn
    error_message = "The regional ACL must be associated with the ALB."
  }

  assert {
    condition = toset([for r in aws_wafv2_web_acl.this.rule : r.name]) == toset([
      "AWSManagedRulesAmazonIpReputationList",
      "AWSManagedRulesCommonRuleSet",
      "AWSManagedRulesKnownBadInputsRuleSet",
      "rate-limit-per-ip",
    ])
    error_message = "The ACL must have the three managed rule groups and the rate-based rule."
  }

  assert {
    condition = [
      for r in aws_wafv2_web_acl.this.rule : r.statement[0].rate_based_statement[0].limit
      if length(r.statement[0].rate_based_statement) > 0
    ] == [2000]
    error_message = "The rate-based rule must allow 2000 requests per IP per 5 minutes."
  }
}

run "waf_cloudfront_acl_has_no_association" {
  command = plan

  module {
    source = "../../modules/waf"
  }

  variables {
    scope = "CLOUDFRONT"
  }

  assert {
    condition     = aws_wafv2_web_acl.this.scope == "CLOUDFRONT"
    error_message = "The ACL must use CLOUDFRONT scope."
  }

  assert {
    condition     = length(aws_wafv2_web_acl_association.this) == 0
    error_message = "A CLOUDFRONT ACL is attached through web_acl_id, not an association."
  }
}

############################
# Positive cases: with domain
############################

run "acm_certificate_with_domain_is_validated" {
  command = plan

  module {
    source = "../../modules/acm-certificate"
  }

  variables {
    domain_name    = "api.example.com"
    hosted_zone_id = "Z0000000000000EXAMPLE"
  }

  assert {
    condition = (
      length(aws_acm_certificate.this) == 1 &&
      length(aws_route53_record.validation) == 1 &&
      length(aws_acm_certificate_validation.this) == 1
    )
    error_message = "One DNS-validated certificate must be created."
  }

  assert {
    condition     = aws_acm_certificate.this[0].validation_method == "DNS"
    error_message = "The certificate must use DNS validation."
  }
}

run "load_balancer_with_domain_serves_https" {
  command = plan

  module {
    source = "../../modules/load_balancer"
  }

  variables {
    environment     = "prod"
    domain_name     = "api.example.com"
    certificate_arn = "arn:aws:acm:eu-central-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(aws_lb_listener.https) == 1
    error_message = "A 443 listener must be created with a domain."
  }

  assert {
    condition = (
      aws_lb_listener.https[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06" &&
      aws_lb_listener.https[0].certificate_arn == var.certificate_arn
    )
    error_message = "The 443 listener must use the certificate and the TLS 1.3/1.2 policy."
  }

  assert {
    condition = (
      aws_lb_listener.app.default_action[0].type == "redirect" &&
      aws_lb_listener.app.default_action[0].redirect[0].protocol == "HTTPS" &&
      aws_lb_listener.app.default_action[0].redirect[0].status_code == "HTTP_301"
    )
    error_message = "Port 80 must redirect to HTTPS with a 301."
  }

  assert {
    condition = (
      one([for c in aws_lb_listener_rule.block_metrics.condition : one(c.path_pattern).values]) == toset(["/metrics*", "/api/metrics*"]) &&
      aws_lb_listener_rule.block_metrics.action[0].fixed_response[0].status_code == "404"
    )
    error_message = "/metrics* and /api/metrics* must return 404 on the 443 listener."
  }

  assert {
    condition     = aws_lb.app.enable_deletion_protection
    error_message = "Deletion protection must be on in prod."
  }
}

run "dns_with_domain_creates_alias_records" {
  command = plan

  module {
    source = "../../modules/dns"
  }

  variables {
    domain_name      = "example.com"
    hosted_zone_name = "example.com"
    api_domain_name  = "api.example.com"
  }

  assert {
    condition     = length(aws_route53_record.api) == 1 && aws_route53_record.api[0].name == "api.example.com"
    error_message = "One A alias record must point the API domain at the ALB."
  }

  assert {
    condition     = toset(keys(aws_route53_record.web)) == toset(["A", "AAAA"])
    error_message = "A and AAAA alias records must point the web domain at CloudFront."
  }

  assert {
    condition     = output.zone_id == "Z0000000000000EXAMPLE"
    error_message = "zone_id must come from the hosted zone lookup."
  }
}

run "frontend_with_domain_uses_acm_certificate" {
  command = plan

  module {
    source = "../../modules/frontend"
  }

  variables {
    domain_name         = "example.com"
    acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = aws_cloudfront_distribution.web_client.aliases == toset(["example.com"])
    error_message = "The distribution must serve the custom domain."
  }

  assert {
    condition = (
      !aws_cloudfront_distribution.web_client.viewer_certificate[0].cloudfront_default_certificate &&
      aws_cloudfront_distribution.web_client.viewer_certificate[0].acm_certificate_arn == var.acm_certificate_arn &&
      aws_cloudfront_distribution.web_client.viewer_certificate[0].minimum_protocol_version == "TLSv1.2_2021" &&
      aws_cloudfront_distribution.web_client.viewer_certificate[0].ssl_support_method == "sni-only"
    )
    error_message = "The custom certificate must be served over SNI with TLS 1.2 minimum."
  }
}
