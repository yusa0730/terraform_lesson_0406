resource "aws_security_group" "ecs" {
  name_prefix = "ecs_sg_"

  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    self            = false
    security_groups = ["${aws_security_group.nlb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-${local.env}-ecs-sg"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_policy" {
  name = "ecr_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  policy_arn = aws_iam_policy.ecr_policy.arn
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_ecr_repository" "main" {
  name = "${local.env}-ecr"
}

resource "aws_ecs_cluster" "main" {
  name = "${local.env}-ecs-cluster"
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${local.env}-test-taskdef"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name   = "${local.env}-ecs-container"
    image  = "${aws_ecr_repository.main.repository_url}:latest"
    cpu    = 256
    memory = 512
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
    log_configuration = {
      log_driver = "awslogs"
      options = {
        "awslogs-region"        = "${local.region}"
        "awslogs-group"         = "/ecs/${local.env}/app"
        "awslogs-stream-prefix" = "app"
      }
    }
  }])
}

resource "aws_ecs_service" "main" {
  name                              = "${local.env}-ecs-service"
  cluster                           = aws_ecs_cluster.main.arn
  task_definition                   = aws_ecs_task_definition.main.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs.id]

    subnets = [
      "${aws_subnet.ecs_private_a.id}",
      "${aws_subnet.ecs_private_c.id}"
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "${local.env}-ecs-container"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
