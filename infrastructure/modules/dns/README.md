<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.35 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.35 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_route53_record.api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alb_dns_name"></a> [alb\_dns\_name](#input\_alb\_dns\_name) | ALB DNS name | `string` | n/a | yes |
| <a name="input_alb_zone_id"></a> [alb\_zone\_id](#input\_alb\_zone\_id) | ALB canonical hosted zone ID | `string` | n/a | yes |
| <a name="input_api_domain_name"></a> [api\_domain\_name](#input\_api\_domain\_name) | API domain that points to the ALB | `string` | `""` | no |
| <a name="input_cloudfront_domain_name"></a> [cloudfront\_domain\_name](#input\_cloudfront\_domain\_name) | CloudFront distribution domain name | `string` | n/a | yes |
| <a name="input_cloudfront_zone_id"></a> [cloudfront\_zone\_id](#input\_cloudfront\_zone\_id) | CloudFront distribution hosted zone ID | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Web client domain served by CloudFront. Empty disables every record in this module | `string` | `""` | no |
| <a name="input_hosted_zone_name"></a> [hosted\_zone\_name](#input\_hosted\_zone\_name) | Public Route 53 hosted zone that contains domain\_name | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Hosted zone ID, empty when no domain is configured |
<!-- END_TF_DOCS -->