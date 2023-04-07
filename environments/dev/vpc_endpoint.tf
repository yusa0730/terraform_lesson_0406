resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "vpc_endpoint_sg_"

  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.nlb.id}"]
  }

  tags = {
    Name = "${local.project_name}-${local.env}-vpc_endpoint_sg"
  }
}

resource "aws_security_group" "ecr_vpc_endpoint_sg" {
  name_prefix = "ecr_vpc_endpoint_sg_"
  vpc_id      = aws_vpc.vpc.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    self        = false
  }

  ingress {
    description     = "from ECS"
    from_port       = "0"
    to_port         = "0"
    protocol        = "-1"
    self            = false
    security_groups = ["${aws_security_group.ecs.id}"]
  }
}

# vpc endpoint
resource "aws_vpc_endpoint" "endpoint_from_api_gateway_to_nlb" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${local.region}.elasticloadbalancing"
  security_group_ids  = ["${aws_security_group.vpc_endpoint.id}"]
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"
  subnet_ids = [
    "${aws_subnet.nlb_private_a.id}",
    "${aws_subnet.nlb_private_c.id}"
  ]

  tags = {
    "Name" = "${local.env}-endpoint-elasticloadbalancing"
  }
}

resource "aws_vpc_endpoint" "to_ecr_dkr" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${local.region}.ecr.dkr"
  security_group_ids  = ["${aws_security_group.ecr_vpc_endpoint_sg.id}"]
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"
  subnet_ids = [
    "${aws_subnet.ecs_private_a.id}",
    "${aws_subnet.ecs_private_c.id}"
  ]

  tags = {
    "Name" = "${local.env}-endpoint-ecr.dkr"
  }
}
