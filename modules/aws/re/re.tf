terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


###########################################################
# EC2

resource "aws_instance" "node" {
  ami = var.ami 
  instance_type = var.instance_type
  availability_zone = var.zones[count.index % length(var.zones)]
  subnet_id = var.subnet
  vpc_security_group_ids = var.security_groups
  key_name = var.ssh_key_name
  count    = var.worker_count

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

  tags = {
    Name = "${var.name}-node-0"
  }
}

