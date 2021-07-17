terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


############################################################
# Key Pair

resource "aws_key_pair" "peypair" {
  key_name = "${var.name}-keypair"
  public_key = file(var.ssh_public_key)

  tags = {
    Name = "${var.name}-keypair"
  }
}
