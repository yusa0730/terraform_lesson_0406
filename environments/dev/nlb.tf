resource "aws_security_group" "nlb" {
  egress {
    description = "to ecs"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "nlb_sg_ingress_from_vpc_endpoint_80" {
  description              = "from VPCEndpoint"
  type                     = "ingress"
  security_group_id        = aws_security_group.nlb.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoint.id
}

# NLB
resource "aws_lb" "nlb" {
  name               = "${local.env}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets = [
    "${aws_subnet.nlb_private_a.id}",
    "${aws_subnet.nlb_private_c.id}"
  ]
  # security_groups    = [aws_security_group.nlb.id]
}

resource "aws_lb_target_group" "example" {
  name                 = "tg2"
  target_type          = "ip"
  vpc_id               = aws_vpc.vpc.id
  port                 = 80
  protocol             = "TCP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [
    aws_lb.nlb
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}
