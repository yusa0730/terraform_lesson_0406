# API Gateway
resource "aws_api_gateway_vpc_link" "vpc_link" {
  name = "${local.project_name}-${local.env}-vpc-link"

  target_arns = ["${aws_lb.nlb.arn}"]
}

resource "aws_api_gateway_rest_api" "example" {
  name        = "example-api-gateway"
  description = "Example API Gateway"
}

resource "aws_api_gateway_resource" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_resource.example.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "test_get" {
  rest_api_id             = aws_api_gateway_rest_api.example.id
  resource_id             = aws_api_gateway_resource.example.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.nlb.dns_name}"

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.vpc_link.id
}

resource "aws_api_gateway_deployment" "example" {
  depends_on  = [aws_api_gateway_integration.test_get]
  rest_api_id = aws_api_gateway_rest_api.example.id
  stage_name  = "dev"
  description = "Example API Gateway Deployment"
}
