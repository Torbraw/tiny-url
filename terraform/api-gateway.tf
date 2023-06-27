resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "http-api-gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "tiny_url_integration" {
  api_id                 = aws_apigatewayv2_api.api_gateway.id
  payload_format_version = "2.0"
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.tiny_url_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "tiny_url_route" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "POST /tiny-url"

  target = "integrations/${aws_apigatewayv2_integration.tiny_url_integration.id}"
}

resource "aws_apigatewayv2_deployment" "api_gateway_deployment" {
  api_id = aws_apigatewayv2_api.api_gateway.id

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_integration.tiny_url_integration),
      jsonencode(aws_apigatewayv2_route.tiny_url_route),
    ])))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "api_gateway_stage" {
  api_id = aws_apigatewayv2_api.api_gateway.id
  name   = "v1"

  deployment_id = aws_apigatewayv2_deployment.api_gateway_deployment.id
}
