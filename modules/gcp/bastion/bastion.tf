terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

resource "google_compute_address" "bastion-ip-address" {
  name  = "${var.name}-bastion-ip-address"
}

resource "google_compute_instance" "bastion" {
  name         = "${var.name}-bastion"
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

}
