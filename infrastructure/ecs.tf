# ECSクラスター
resource "aws_ecs_cluster" "main" {
  name = "iam-manager-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "iam-manager-cluster"
    Environment = var.environment
  }
}

# CloudWatch Logs グループ
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/iam-manager"
  retention_in_days = 30

  tags = {
    Name        = "iam-manager-logs"
    Environment = var.environment
  }
}

# ECSタスク定義
resource "aws_ecs_task_definition" "app" {
  family                   = "iam-manager"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${var.backend_image}:${var.image_tag}"
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "AWS_ACCOUNTS"
          value = var.aws_accounts
        },
        {
          name  = "AWS_DEFAULT_REGION"
          value = var.aws_region
        },
        {
          name  = "DYNAMODB_TABLE_NAME"
          value = aws_dynamodb_table.iam_audit_logs.name
        },
        {
          name  = "SES_FROM_EMAIL"
          value = var.ses_from_email
        },
        {
          name  = "SES_TO_EMAILS"
          value = var.ses_to_emails
        },
        {
          name  = "CORS_ORIGINS"
          value = "https://${var.domain_name}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
    },
    {
      name  = "frontend"
      image = "${var.frontend_image}:${var.image_tag}"
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])

  tags = {
    Name        = "iam-manager-task"
    Environment = var.environment
  }
}

# ECSサービス
resource "aws_ecs_service" "app" {
  name            = "iam-manager-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.app]

  tags = {
    Name        = "iam-manager-service"
    Environment = var.environment
  }
}

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "iam-manager-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.private_subnets

  tags = {
    Name        = "iam-manager-alb"
    Environment = var.environment
  }
}

# ALBターゲットグループ
resource "aws_lb_target_group" "app" {
  name        = "iam-manager-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 60
    interval            = 300
    matcher             = "200"
  }

  tags = {
    Name        = "iam-manager-tg"
    Environment = var.environment
  }
}

# ALBリスナー
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# HTTP to HTTPS リダイレクト
resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALBセキュリティグループ
resource "aws_security_group" "alb" {
  name        = "iam-manager-alb-sg"
  description = "Security group for IAM Manager ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "iam-manager-alb-sg"
    Environment = var.environment
  }
}

# ECSタスクセキュリティグループ
resource "aws_security_group" "ecs_tasks" {
  name        = "iam-manager-ecs-tasks-sg"
  description = "Security group for IAM Manager ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "iam-manager-ecs-tasks-sg"
    Environment = var.environment
  }
}
