resource "aws_lb" "mercury_app_lb" {
  name               = "MercuryProd-AppLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnet_groups

  tags = {
    Environment = "Production"
  }
}

resource "aws_lb_target_group" "mercury_app_lb_target_group_react" {
  name     = "MercuryProd-AppLB-TG-React"
  port     = 80
  protocol = "HTTP"
  slow_start = 60
  vpc_id   = "${var.vpc_id}"
  target_type = "instance"
  health_check {
    enabled = true
    port = 80
    path = "/"
    timeout = "20"
    healthy_threshold = 2
    interval = 30
  }
}

resource "aws_lb_target_group" "mercury_app_lb_target_group_api" {
  name     = "MercuryProd-AppLB-TG-API"
  port     = 80
  protocol = "HTTP"
  slow_start = 60
  vpc_id   = "${var.vpc_id}"
  target_type = "instance"
  health_check {
    enabled = true
    port = 80
    path = "/"
    timeout = "20"
    healthy_threshold = 2
    interval = 30
  }
}

resource "aws_lb_listener" "mercury_app_lb_listener_react" {
  load_balancer_arn = aws_lb.mercury_app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mercury_app_lb_target_group_react.arn
  }
}

resource "aws_lb_listener" "mercury_app_lb_listener_api" {
  load_balancer_arn = aws_lb.mercury_app_lb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mercury_app_lb_target_group_api.arn
  }
}