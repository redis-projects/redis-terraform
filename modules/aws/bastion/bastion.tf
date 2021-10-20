terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


############################################################
# Network Interface

resource "aws_network_interface" "nic" {
  subnet_id = var.subnet
  security_groups = var.security_groups

  tags = {
    Name = "${var.vpc}-${var.name}-nic"
  }
}


# Elastic IP to the Network Interface
resource "aws_eip" "eip" {
  vpc = true
  network_interface = aws_network_interface.nic.id
  associate_with_private_ip = aws_network_interface.nic.private_ip

  tags = {
    Name = "${var.name}-eip"
  }
}


############################################################
# EC2

resource "aws_instance" "bastion" {
  ami = var.ami 
  instance_type = var.instance_type
  availability_zone = var.availability_zone
  key_name = var.ssh_key_name
  user_data = <<-EOF
    #cloud-config
    cloud_final_modules:
    - [users-groups,always]
    users:
      - name: ${var.redis_user}
        groups: [ wheel ]
        sudo: [ "ALL=(ALL) NOPASSWD:ALL" ]
        shell: /bin/bash
        ssh-authorized-keys:
        - ${file(var.ssh_public_key)}
        EOF

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.nic.id
  }

  tags = {
    Name = "${var.name}-bastion"
  }
}

