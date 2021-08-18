terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

resource "google_compute_address" "bastion-ip-address" {
  name  = "${var.vpc}-${var.random_id}-bastion-ip-address"
}

resource "google_compute_instance" "bastion" {
  name         = "${var.vpc}-${var.random_id}-bastion"
  machine_type = var.bastion_machine_type
  zone         = var.zone

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

    access_config {
      nat_ip  = google_compute_address.bastion-ip-address.address
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
    content  = var.active_active_script.rendered
    destination = "/home/${var.gce_ssh_user}/create_aa_db.sh"

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

  provisioner "file" {
    source      = "./bin/post_provision.sh"
    destination = "/home/${var.gce_ssh_user}/post_provision.sh"

    connection {
      type        = "ssh"
      user        = var.gce_ssh_user
      private_key = file(var.gce_ssh_private_key_file)
      host        = google_compute_address.bastion-ip-address.address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.gce_ssh_user}/post_provision.sh",
      "/home/${var.gce_ssh_user}/post_provision.sh ${var.redis_distro} | tee  post_provision.out 2>&1",
    ]

    connection {
      type        = "ssh"
      user        = var.gce_ssh_user
      private_key = file(var.gce_ssh_private_key_file)
      host        = google_compute_address.bastion-ip-address.address
    }
  }
}
