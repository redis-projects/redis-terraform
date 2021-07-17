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
  private_ips = ["10.0.1.50"]
  security_groups = var.security_groups

  tags = {
    Name = "${var.vpc}-${var.name}-nic"
  }
}


# Elastic IP to the Network Interface
resource "aws_eip" "eip" {
  vpc = true
  network_interface = aws_network_interface.nic.id
  associate_with_private_ip = "10.0.1.50"
  #depends_on = [var.igw]

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
   #content = templatefile("templates/extra-vars.tpl", {
   #   ansible_user: var.redis-user,
   #   redis_cluster_name: var.redis-cluster-name,
   #   redis_user_name: var.redis-username,
   #   redis_pwd: var.redis-password,
   #   redis_email_from: var.redis-email,
   #   redis_smtp_host: var.redis-smtp
   # })
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

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update --nogpgcheck && sudo yum install -y git --nogpgcheck && sudo amazon-linux-extras install -y ansible2",
      "cd /home/${var.ssh_user} && tar -xf redis-ansible.tar.gz",
      "cd /home/${var.ssh_user} && mv /home/${var.ssh_user}/boa-inventory.ini /home/${var.ssh_user}/redis-ansible/inventories/boa-cluster.ini",
      "cd /home/${var.ssh_user} && mv /home/${var.ssh_user}/boa-extra-vars.yaml /home/${var.ssh_user}/redis-ansible/extra_vars/boa-extra-vars.yaml",
      "export ANSIBLE_HOST_KEY_CHECKING=False && cd /home/${var.ssh_user}/redis-ansible && ansible-playbook -i ./inventories/boa-cluster.ini redislabs-install.yaml -e @./extra_vars/boa-extra-vars.yaml -e @./group_vars/all/main.yaml -e re_url=${var.redis_distro} && ansible-playbook -i ./inventories/boa-cluster.ini redislabs-create-cluster.yaml -e @./extra_vars/boa-extra-vars.yaml -e @./group_vars/all/main.yaml"
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

