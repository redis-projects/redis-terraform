resource "null_resource" "create_docker_service" {

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /content/",
      "sudo chown ${var.ssh_user}:${var.ssh_user} /content/",
      "sudo usermod -a -G docker ${var.ssh_user}", 
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_private_key_file)
      host        = var.host
    }

  }

  provisioner "file" {
    source  = "./modules/docker/services/${var.contents}"
    destination = "/content/${var.contents}"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_private_key_file)
      host        = var.host
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cd /content/${var.contents}",
      "bash ${var.start_script} | tee start.log 2>&1",
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.ssh_private_key_file)
      host        = var.host
    }
  }
}