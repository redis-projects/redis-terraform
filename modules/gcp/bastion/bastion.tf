resource "google_compute_address" "bastion-ip-address" {
  name  = "${var.vpc}-${var.random_id}-bastion-ip-address"
}

resource "google_compute_instance" "bastion" {
  name         = "${var.vpc}-${var.random_id}-bastion"
  machine_type = var.bastion_machine_type

  #can_ip_forward  = true

  tags = ["kubernetes-the-easy-way", "bastion"]

  boot_disk {
    initialize_params {
      image = var.os
      size  = var.boot_disk_size
    }
  }


  network_interface {
    subnetwork = var.subnet

    #network_ip = "10.10.0.${count.index+2}"

    access_config {
      nat_ip  = google_compute_address.bastion-ip-address.address
      #nat_ip  = element(google_compute_address.bastion-ip-address.*.address, count.index)
    }
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  provisioner "file" {
    content  = var.inventory.rendered
    destination = "/home/${var.gce_ssh_user}/boa-inventory.ini"

    connection {
      type        = "ssh"
      user        = var.gce_ssh_user
      private_key = file(var.gce_ssh_private_key_file)
      host        = google_compute_address.bastion-ip-address.address
    }
  }

  provisioner "file" {
    content  = var.extra_vars.rendered
    destination = "/home/${var.gce_ssh_user}/boa-extra-vars.yaml"

    connection {
      type        = "ssh"
      user        = var.gce_ssh_user
      private_key = file(var.gce_ssh_private_key_file)
      host        = google_compute_address.bastion-ip-address.address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update --nogpgcheck && sudo yum install -y git --nogpgcheck && sudo yum install -y ansible --nogpgcheck",
      "cd /home/${var.gce_ssh_user} && git clone --branch tune_ups https://${var.ansible_repo_creds}@github.com/reza-rahim/redis-ansible",
      "cd /home/${var.gce_ssh_user} && mv /home/${var.gce_ssh_user}/boa-inventory.ini /home/${var.gce_ssh_user}/redis-ansible/inventories/boa-cluster.ini",
      "cd /home/${var.gce_ssh_user} && mv /home/${var.gce_ssh_user}/boa-extra-vars.yaml /home/${var.gce_ssh_user}/redis-ansible/extra_vars/boa-extra-vars.yaml",
      "export ANSIBLE_HOST_KEY_CHECKING=False && cd /home/${var.gce_ssh_user}/redis-ansible && ansible-playbook -i ./inventories/boa-cluster.ini redislabs-install.yaml -e @./extra_vars/boa-extra-vars.yaml -e @./group_vars/all/main.yaml -e re_url=${var.redis_distro} && ansible-playbook -i ./inventories/boa-cluster.ini redislabs-create-cluster.yaml -e @./extra_vars/boa-extra-vars.yaml -e @./group_vars/all/main.yaml"
    ]

    connection {
      type        = "ssh"
      user        = var.gce_ssh_user
      private_key = file(var.gce_ssh_private_key_file)
      host        = google_compute_address.bastion-ip-address.address
    }
  }
}