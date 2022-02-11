terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

###########################################################
# Network Interface

resource "aws_network_interface" "service_nic" {
  subnet_id       = var.subnet[count.index % length(var.zones)].id
  security_groups = var.security_groups
  count           = var.node_count

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-service-nic-${count.index}"
  })
}

resource "aws_eip" "eip" {
  vpc                       = true
  count                     = var.node_count
  network_interface         = aws_network_interface.service_nic[count.index].id
  associate_with_private_ip = aws_network_interface.service_nic[count.index].private_ip
  depends_on                = [aws_instance.node]

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-service-eip-${count.index}"
  })
}

###########################################################
# EC2

resource "aws_instance" "node" {
  ami = var.ami 
  instance_type = var.instance_type
  availability_zone = sort(var.zones)[count.index % length(var.zones)]
  key_name = var.ssh_key_name
  count    = var.node_count

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.service_nic[count.index].id
  }

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

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-service-${count.index}"
  })
}

