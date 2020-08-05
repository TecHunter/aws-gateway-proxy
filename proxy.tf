provider "aws" {
  region = var.region
  profile = var.profile
}

resource "aws_api_gateway_rest_api" "ApiGateway" {
  name = var.api_name
  description = var.api_description
}

resource "aws_api_gateway_resource" "ApiProxyResource" {
  rest_api_id = aws_api_gateway_rest_api.ApiGateway.id
  parent_id = aws_api_gateway_rest_api.ApiGateway.root_resource_id

  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "ApiProxyMethod" {
  rest_api_id = aws_api_gateway_rest_api.ApiGateway.id
  resource_id = aws_api_gateway_resource.ApiProxyResource.id

  http_method = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "ApiProxyIntegration" {
  rest_api_id = aws_api_gateway_rest_api.ApiGateway.id
  resource_id = aws_api_gateway_resource.ApiProxyResource.id
  http_method = aws_api_gateway_method.ApiProxyMethod.http_method

  type = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri = "${var.base_url}/{proxy}"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "ApiDeployment" {
  depends_on = [
    aws_api_gateway_integration.ApiProxyIntegration]
  rest_api_id = aws_api_gateway_rest_api.ApiGateway.id

  stage_name = var.stage
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "selected" {
  name = "${var.domain}."
  private_zone = false
}

resource "aws_acm_certificate" "subdomain" {
  domain_name = "${var.subdomain}.${var.domain}"
}

resource "aws_acm_certificate_validation" "proxyRecordCertValidation" {
  certificate_arn = aws_acm_certificate.subdomain.arn
  validation_record_fqdns = [
    aws_acm_certificate.subdomain.domain_name
  ]
}

resource "aws_api_gateway_domain_name" "proxyDomain" {
  domain_name = aws_acm_certificate.subdomain.domain_name
  certificate_arn = aws_acm_certificate_validation.proxyRecordCertValidation.certificate_arn
  depends_on = [
    aws_acm_certificate_validation.proxyRecordCertValidation
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
