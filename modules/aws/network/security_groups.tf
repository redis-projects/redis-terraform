############################################################
# Security Groups

resource "aws_security_group" "allow-ssh" {
  name = "${var.name}-allow-ssh"
  description = "Allow inbound traffic"
  vpc_id = aws_vpc.vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-allow-ssh"
  })
}

resource "aws_security_group" "allow-crdb" {
  name = "${var.name}-allow-crdb"
  description = "Allow inbound crdb creation specific traffic"
  vpc_id = aws_vpc.vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-allow-crdb"
  })
}

resource "aws_security_group" "allow-local" {
  name = "${var.name}-allow-local"
  description = "Allow inbound traffic from local VPC"
  vpc_id = aws_vpc.vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-allow-local"
  })
}

############################################################
# Security Group Rules

resource "aws_security_group_rule" "public_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SSH traffic"
  security_group_id = aws_security_group.allow-ssh.id
}

resource "aws_security_group_rule" "public_outgoing" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Outgoing Traffic"
  security_group_id = aws_security_group.allow-ssh.id
}

resource "aws_security_group_rule" "private_DNS" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "DNS traffic"
  security_group_id = aws_security_group.allow-local.id
}

resource "aws_security_group_rule" "local_private_traffic" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Local traffic"
  security_group_id = aws_security_group.allow-local.id
}

resource "aws_security_group_rule" "vpn_traffic" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${var.private_subnet_list[count.index]}"]
  description       = "VPN traffic from ${var.private_subnet_list[count.index]}"
  security_group_id = aws_security_group.allow-local.id
  count             = length(var.vpn_list)
}

resource "aws_security_group_rule" "private_am_gui" {
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SM GUI connection"
  security_group_id = aws_security_group.allow-local.id
}

resource "aws_security_group_rule" "private_outgoing" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Outgoing Traffic"
  security_group_id = aws_security_group.allow-local.id
}

resource "aws_security_group_rule" "private_req" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_map[var.peer_request_list[count.index]]]
  description       = "peer traffic ${var.peer_request_list[count.index]}"
  security_group_id = aws_security_group.allow-local.id
  count             = length(var.peer_request_list)
}

resource "aws_security_group_rule" "public_req" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_map[var.peer_request_list[count.index]]]
  description       = "peer traffic ${var.peer_request_list[count.index]}"
  security_group_id = aws_security_group.allow-ssh.id
  count             = length(var.peer_request_list)
}

resource "aws_security_group_rule" "public_acc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_map[var.peer_accept_list[count.index]]]
  description       = "peer traffic ${var.peer_accept_list[count.index]}"
  security_group_id = aws_security_group.allow-ssh.id
  count             = length(var.peer_accept_list)
}

resource "aws_security_group_rule" "private_acc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_map[var.peer_accept_list[count.index]]]
  description       = "peer traffic ${var.peer_accept_list[count.index]}"
  security_group_id = aws_security_group.allow-local.id
  count             = length(var.peer_accept_list)
}

resource "aws_security_group_rule" "public_crdb_creation_api" {
  type              = "ingress"
  from_port         = 9443
  to_port           = 9443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SM GUI connection"
  security_group_id = aws_security_group.allow-crdb.id
}

resource "aws_security_group_rule" "public_crdb_syncer_api" {
  type              = "ingress"
  from_port         = 12000
  to_port           = 12000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "SM GUI connection"
  security_group_id = aws_security_group.allow-crdb.id
}
