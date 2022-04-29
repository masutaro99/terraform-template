#----------------------------------------
# ALB
#----------------------------------------
resource "aws_lb" "alb" {
  name                       = "${var.system_name}-${var.env_name}-alb"
  load_balancer_type         = "application"
  internal                   = "false"
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    aws_subnet.public-subnet-1.id,
    aws_subnet.public-subnet-2.id,
  ]

  security_groups = [
    module.https_sg.security_group_id
  ]
}

#----------------------------------------
# HTTP
#----------------------------------------
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cert.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "test_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

module "https_sg" {
  source      = "./module/security_group"
  name        = "${var.system_name}-${var.env_name}-alb-https-sg"
  vpc_id      = aws_vpc.vpc.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_test_http" {
  type      = "ingress"
  from_port = 8080
  to_port   = 8080
  protocol  = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]
  security_group_id = module.https_sg.security_group_id
}

#----------------------------------------
# Target Group
#----------------------------------------
resource "aws_lb_target_group" "blue" {
  name                 = "${var.system_name}-${var.env_name}-ecs-tg-blue"
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.vpc.id
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
}

resource "aws_lb_target_group" "green" {
  name                 = "${var.system_name}-${var.env_name}-ecs-tg-green"
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.vpc.id
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

}

#----------------------------------------
# Output
#----------------------------------------
output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}
