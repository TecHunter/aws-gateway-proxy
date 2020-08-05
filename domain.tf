
resource "aws_api_gateway_domain_name" "proxyDomain" {
  certificate_arn = aws_acm_certificate_validation.validation.certificate_arn
  domain_name = aws_acm_certificate.subdomain.domain_name
  depends_on = [
    # wait for certificate validation
    aws_acm_certificate_validation.validation
  ]
}

resource "aws_route53_record" "proxyRecord" {
  zone_id = data.aws_route53_zone.selected.id
  name = aws_api_gateway_domain_name.proxyDomain.domain_name
  type = "A"

  allow_overwrite = true
  alias {
    evaluate_target_health = true
    name = aws_api_gateway_domain_name.proxyDomain.regional_domain_name
    zone_id = aws_api_gateway_domain_name.proxyDomain.regional_zone_id
  }
}
