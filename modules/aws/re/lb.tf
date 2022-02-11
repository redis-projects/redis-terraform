# Create target Group
resource "aws_lb_target_group" "dns" {
  name        = "${var.name}-dns-tg"
  port        = 53
  protocol    = "UDP"
  target_type = "ip"
  vpc_id      = var.vpc
  tags        = "${var.resource_tags}"
  health_check {
      port = 8443
      protocol = "HTTPS"
      healthy_threshold = 3
      unhealthy_threshold = 3
      interval = 10
  }
}

# Attach all nodes to the target group
resource "aws_lb_target_group_attachment" "tg-ips" {
  target_group_arn = aws_lb_target_group.dns.arn
  target_id        = aws_instance.node[count.index].private_ip
  port             = 53
  count            = length(aws_instance.node)
}

# create NLB (Network Load Balancer)
resource "aws_lb" "dns-lb" {
  name                       = "${var.name}-dns-lb"
  internal                   = false
  load_balancer_type         = "network"
  subnets                    = [for sub in var.lb_subnet : sub.id]
  enable_deletion_protection = false
  tags                       = "${var.resource_tags}"
}

# Create Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.dns-lb.arn
  port              = "53"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dns.arn
  }
  tags        = "${var.resource_tags}"
}
