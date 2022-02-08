terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

resource "google_compute_instance" "node" {
  count           = var.kube_worker_machine_count
  name            = "${var.name}-service-${count.index}"
  machine_type    = var.kube_worker_machine_type
  zone            = var.zones[count.index % length(var.zones)]
  can_ip_forward  = true

  boot_disk {
    initialize_params {
      image = var.kube_worker_machine_image
      size  = var.boot_disk_size
    }
  }

  network_interface {
    subnetwork = var.subnet
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = "yum -y update --nogpgcheck;"
}
