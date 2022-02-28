terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Create target Group
resource "aws_lb_target_group" "re-ui" {
  name        = "${var.name}-lb-tg"
  port        = 8443
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.vpc
  tags        = "${var.resource_tags}"
}

# Attach all nodes to the target group
resource "aws_lb_target_group_attachment" "tg-ips" {
  target_group_arn = aws_lb_target_group.re-ui.arn
  target_id        = var.ips[count.index]
  port             = 8443
  count            = length(var.ips)
}

# create NLB (Network Load Balancer)
resource "aws_lb" "re-gui" {
  name                       = "${var.name}-lb"
  internal                   = length(var.ui_subnets) == 0 ? false : true
  load_balancer_type         = "network"
  subnets                    = length(var.ui_subnets) == 0 ? var.subnets : var.ui_subnets
  enable_deletion_protection = false
  tags                       = "${var.resource_tags}"
}

# Create Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.re-gui.arn
  port              = "8443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.re-ui.arn
  }
  tags        = "${var.resource_tags}"
}
