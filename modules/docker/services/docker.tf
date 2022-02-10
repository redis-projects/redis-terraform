resource "null_resource" "create_docker_service" {
  count   = "${length(var.servicenodes)}"    

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_file)
    host        = element(var.servicenodes.*.private_ip, count.index)

    bastion_host        = var.bastion_host
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /content/",
      "sudo chown ${var.ssh_user}:${var.ssh_user} /content/",
      "sudo usermod -a -G docker ${var.ssh_user}", 
    ]

  }

  provisioner "file" {
    source  = "./modules/docker/services/${var.contents}"
    destination = "/content/${var.contents}"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /content/${var.contents}",
      "bash ${var.start_script} | tee start.log 2>&1",
    ]
  }
}