resource "aws_acm_certificate" "subdomain" {
  provider = aws.cert-provider
  domain_name = "${var.subdomain}.${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  provider = aws.cert-provider
  for_each = {
  for dvo in aws_acm_certificate.subdomain.domain_validation_options : dvo.domain_name => {
    name = dvo.resource_record_name
    record = dvo.resource_record_value
    type = dvo.resource_record_type
  }
  }

  name = each.value.name
  records = [
    each.value.record
  ]
  ttl = 60
  type = each.value.type
  zone_id = data.aws_route53_zone.selected.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  provider = aws.cert-provider
  certificate_arn = aws_acm_certificate.subdomain.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
  depends_on = [
    aws_route53_record.validation
  ]
}
