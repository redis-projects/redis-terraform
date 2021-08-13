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
  provisioner "file" {
   content = var.inventory.rendered 
   #content = templatefile("templates/inventory.tpl", { worker_host_name: var.worker-host })
   destination = "/home/${var.ssh_user}/boa-inventory.ini"

    connection {
      type = "ssh"
      host = self.public_ip
      user = var.ssh_user
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "file" {
   content  = var.extra_vars.rendered 
   destination = "/home/${var.ssh_user}/boa-extra-vars.yaml"

    connection {
      type = "ssh"
      host = self.public_ip
      user = var.ssh_user
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "file" {
    source = "bin/redis-ansible.tar.gz"
    destination = "/home/${var.ssh_user}/redis-ansible.tar.gz"

    connection {
      type = "ssh"
      host = self.public_ip
      user = var.ssh_user
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "file" {
    source      = "./bin/post_provision.sh"
    destination = "/home/${var.ssh_user}/post_provision.sh"

    connection {
      type = "ssh"
      host = self.public_ip
      user = var.ssh_user
      private_key = file(var.ssh_private_key)
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.ssh_user}/post_provision.sh",
      "/home/${var.ssh_user}/post_provision.sh ${var.redis_distro} > post_provision.out 2>&1",
    ]

    connection {
      type = "ssh"
      host = self.public_ip
      user = var.ssh_user
      private_key = file(var.ssh_private_key)
    }
  }

  tags = {
    Name = "${var.name}-bastion"
  }
}

