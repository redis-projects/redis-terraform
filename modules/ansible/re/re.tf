resource "null_resource" "null_provisioner" {

  provisioner "file" {
    content  = var.inventory.rendered
    destination = "/home/${var.ssh_user}/boa-inventory.ini"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_private_key_file)
      host        = var.host
    }
  }

  #provisioner "file" {
  #  content  = var.active_active_script.rendered
  #  destination = "/home/${var.ssh_user}/create_aa_db.sh"

  #  connection {
  #    type        = "ssh"
  #    user        = var.ssh_user
  #    private_key = file(var.ssh_private_key_file)
  #    host        = var.host
  #  }
  #}

    provisioner "file" {
      content  = var.extra_vars.rendered
      destination = "/home/${var.ssh_user}/boa-extra-vars.yaml"

      connection {
        type        = "ssh"
        user        = var.ssh_user
        private_key = file(var.ssh_private_key_file)
        host        = var.host
      }
    }

    provisioner "file" {
      source      = "./bin/post_provision.sh"
      destination = "/home/${var.ssh_user}/post_provision.sh"

      connection {
        type        = "ssh"
        user        = var.ssh_user
        private_key = file(var.ssh_private_key_file)
        host        = var.host
      }
    }

    provisioner "file" {
      source      = "${var.ssh_private_key_file}"
      destination = "/home/${var.ssh_user}/.ssh/id_rsa"

      connection {
        type        = "ssh"
        user        = var.ssh_user
        private_key = file(var.ssh_private_key_file)
        host        = var.host
      }
    }

    provisioner "remote-exec" {
      inline = [
        "chmod 400 /home/${var.ssh_user}/.ssh/id_rsa",
        "chmod +x /home/${var.ssh_user}/post_provision.sh",
        "/home/${var.ssh_user}/post_provision.sh ${var.redis_distro} | tee  post_provision.out 2>&1",
      ]

      connection {
        type        = "ssh"
        user        = var.ssh_user
        private_key = file(var.ssh_private_key_file)
        host        = var.host
      }
    }

    #provisioner "remote-exec" {
    #  inline = "${concat(["chmod 400 /home/${var.ssh_user}/.ssh/id_rsa"],local.ssh_tunnels, ["sleep 30"])}"

      connection {
        type = "ssh"
        host = var.host
        user = var.ssh_user
        private_key = file(var.ssh_private_key_file)
      }
    }

}
