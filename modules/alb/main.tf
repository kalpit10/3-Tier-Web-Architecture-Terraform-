resource "aws_lb" "this" {
  name               = "final-project-alb"
  internal           = false                 # false = internet-facing
  load_balancer_type = "application"         # This is an ALB
  security_groups    = [var.alb_sg_id]       # We attach the ALB security group
  subnets            = var.public_subnet_ids # Which public subnets to place ALB in

  tags = {
    Name = "final-project-alb"
  }
}


resource "aws_lb_target_group" "this" {
  name        = "final-project-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance" # We're registering EC2s by their instance IDs

  health_check {
    path                = "/index.php"
    protocol            = "HTTP"
    interval            = 30 # in seconds
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "final-project-target-group"
  }
}


resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  # What to do with incoming traffic
  default_action {
    type = "forward"
    # Forward traffic to EC2 TG
    target_group_arn = aws_lb_target_group.this.arn
  }

}