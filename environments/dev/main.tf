locals {
  project_name = "terraform-test"
  env          = "dev"
  region       = "ap-northeast-1"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.project_name}-${local.env}-vpc"
  }
}

resource "aws_subnet" "nlb_private_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${local.region}a"

  tags = {
    Name = "${local.project_name}-${local.env}-nlb-subnet-private-a"
  }
}

resource "aws_subnet" "nlb_private_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "${local.region}c"

  tags = {
    Name = "${local.project_name}-${local.env}-nlb-subnet-private-c"
  }
}

resource "aws_subnet" "ecs_private_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "${local.region}a"

  tags = {
    Name = "${local.project_name}-${local.env}-ecs-subnet-private-a"
  }
}

resource "aws_subnet" "ecs_private_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.40.0/24"
  availability_zone = "${local.region}c"

  tags = {
    Name = "${local.project_name}-${local.env}-ecs-subnet-private-c"
  }
}

# CloudFront
resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = "${aws_api_gateway_rest_api.example.id}.execute-api.${local.region}.amazonaws.com"
    origin_id   = aws_api_gateway_deployment.example.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = ""
  comment             = "example_distribution"

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_api_gateway_deployment.example.id
    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }
}


