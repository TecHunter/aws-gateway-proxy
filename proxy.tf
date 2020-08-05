provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

data "aws_iam_role" "api_user" {
  role_name = "api_user"
}

resource "aws_api_gateway_rest_api" "ApiGateway" {
  name        = "${var.api_name}"
  description = "${var.api_description}"
}

resource "aws_api_gateway_resource" "ApiProxyResource" {
  rest_api_id = "${aws_api_gateway_rest_api.ApiGateway.id}"
  parent_id   = "${aws_api_gateway_rest_api.ApiGateway.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_integration" "ApiProxyIntegration" {
  rest_api_id              = "${aws_api_gateway_rest_api.ApiGateway.id}"
  resource_id              = "${aws_api_gateway_resource.ApiProxyResource.id}"
    http_method              = "${aws_api_gateway_method.ApiProxyMethod.http_method}"
    type                     = "HTTP_PROXY"
    integration_http_method  = "ANY"
    uri                      = "${format("%s/{proxy}", "${var.base_url}")}"
    passthrough_behavior     = "WHEN_NO_MATCH"
    request_parameters       = "${var.aws_api_gateway_integration_request_parameters}"
}

resource "aws_api_gateway_method" "ApiProxyMethod" {
  rest_api_id                   = "${aws_api_gateway_rest_api.ApiGateway.id}"
  resource_id                   = "${aws_api_gateway_resource.ApiProxyResource.id}"
  http_method                   = "ANY"
  request_parameters            = {"method.request.path.proxy" = true}
}

resource "aws_api_gateway_deployment" "ApiDeployment" {
  depends_on = ["aws_api_gateway_method.ApiProxyMethod"]
  rest_api_id = "${aws_api_gateway_rest_api.ApiGateway.id}"
  stage_name = "${var.stage_name}"
}
