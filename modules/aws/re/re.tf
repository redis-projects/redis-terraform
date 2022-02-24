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

resource "aws_network_interface" "cluster_nic" {
  subnet_id       = var.subnet[count.index % length(var.zones)].id
  security_groups = var.security_groups
  count           = var.worker_count

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-cluster-nic-${count.index}"
  })
}


# Elastic IP to the Network Interface
#resource "aws_eip" "eip" {
#  vpc                       = true
#  count                     = var.worker_count
#  network_interface         = aws_network_interface.cluster_nic[count.index].id
#  associate_with_private_ip = aws_network_interface.cluster_nic[count.index].private_ip
#  depends_on                = [aws_instance.node]

#  tags = merge("${var.resource_tags}",{
#    Name = "${var.name}-cluster-eip-${count.index}"
#  })
#}

###########################################################
# EC2

resource "aws_instance" "node" {
  ami = var.ami 
  instance_type = var.instance_type
  availability_zone = sort(var.zones)[count.index % length(var.zones)]
  key_name = var.ssh_key_name
  count    = var.worker_count

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.cluster_nic[count.index].id
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
    Name = "${var.name}-redis-${count.index}"
  })
}

#resource "aws_volume_attachment" "datadisk" {
#  device_name = "/dev/sdc"
#  volume_id   = aws_ebs_volume.datadisk[count.index].id
#  instance_id = aws_instance.node[count.index].id
#  count       = var.worker_count
#}
#resource "aws_ebs_volume" "datadisk" {
#  availability_zone = sort(var.zones)[count.index % length(var.zones)]
#  size              = 5000
#  type              = "gp2"
#  count             = var.worker_count
#
#  tags = merge("${var.resource_tags}",{
#    Name = "${var.name}-datadisk-${count.index}"
#  })
#}

