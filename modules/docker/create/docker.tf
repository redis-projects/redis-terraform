resource "null_resource" "create_docker" {

    provisioner "file" {
      source      = "./modules/docker/create/bin/provision_docker.sh"
      destination = "/home/${var.ssh_user}/provision_docker.sh"

      connection {
        type        = "ssh"
        user        = var.ssh_user
        private_key = file(var.ssh_private_key_file)
        host        = var.host
      }
    }

    provisioner "remote-exec" {
      inline = [
        "chmod +x /home/${var.ssh_user}/provision_docker.sh",
        "/home/${var.ssh_user}/provision_docker.sh | tee provision_docker.log 2>&1",
      ]

      connection {
        type        = "ssh"
        user        = var.ssh_user
        private_key = file(var.ssh_private_key_file)
        host        = var.host
      }
    }
}