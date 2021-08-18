############################################################
# Security Groups

resource "aws_security_group" "allow-ssh" {
  name = "${var.name}-allow-ssh"
  description = "Allow inbound traffic"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-allow-ssh"
  }
}

resource "aws_security_group" "allow-local" {
  name = "${var.name}-allow-local"
  description = "Allow inbound traffic from local VPC"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "DNS"
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Local Traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"   
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-allow-local"
  }
}
