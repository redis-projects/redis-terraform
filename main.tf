provider "google" {
  credentials = file(var.credentials)
  project     = var.var_project
  region      = var.region
  zone        = var.zone
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"

}

################################   ##subnet and route ##########################

resource "google_compute_subnetwork" "public-subnet" {
  name          = "${var.vpc}-${random_id.id.hex}-public-subnet"
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.gce_public_subnet_cidr
}

resource "google_compute_subnetwork" "private-subnet" {
  name          = "${var.vpc}-${random_id.id.hex}-private-subnet"
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.gce_private_subnet_cidr
}

resource "google_compute_router" "router" {
  name    = "${var.vpc}-${random_id.id.hex}-router"
  region  = google_compute_subnetwork.private-subnet.region
  network = google_compute_network.vpc.self_link
  bgp {
    asn = 64514
  }
}


################################ nat  ############################

resource "google_compute_router_nat" "simple-nat" {
  name                               = "${var.vpc}-${random_id.id.hex}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


################################ fire wall ############################


resource "google_compute_firewall" "private-firewall" {
  name    = "${var.vpc}-${random_id.id.hex}-private-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "tcp"
     ports    = ["0-65535"]
  }

  allow {
    protocol = "ipip"
  }

  source_ranges = [var.gce_public_subnet_cidr, var.gce_private_subnet_cidr, "130.211.0.0/22",  "35.191.0.0/16"]
}

resource "google_compute_firewall" "public-firewall" {
  name    = "${var.vpc}-${random_id.id.hex}-public-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22","80", "443", "9443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

########################### bastion ############################ 




resource "google_compute_address" "bastion-ip-address" {
  name  = "${var.vpc}-${random_id.id.hex}-bastion-ip-address"
}

resource "google_compute_instance" "bastion" {
  name         = "${var.vpc}-${random_id.id.hex}-bastion"
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
    subnetwork = google_compute_subnetwork.public-subnet.name

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
    content  = data.template_file.inventory.rendered
    destination = "/home/${var.gce_ssh_user}/boa-inventory.ini"

    connection {
      type        = "ssh"
      user        = var.gce_ssh_user
      private_key = file(var.gce_ssh_private_key_file)
      host        = google_compute_address.bastion-ip-address.address
    }
  }

  provisioner "file" {
    content  = data.template_file.extra_vars.rendered
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

###################### redis nodes #################################

resource "google_compute_instance" "kube-worker" {
  count        = var.kube_worker_machine_count
  name         = "${var.vpc}-${random_id.id.hex}-worker-${count.index}"
  machine_type = var.kube_worker_machine_type

  can_ip_forward  = true

  tags = ["kubernetes-the-easy-way", "kube-worker"]

  boot_disk {
    initialize_params {
      image = var.os
      size  = var.boot_disk_size
    }
  }


  network_interface {
    subnetwork = google_compute_subnetwork.private-subnet.name
    #network_ip = "10.20.0.${count.index+3}"
  }

  service_account {
    scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = "yum -y update --nogpgcheck;"
}

####################### create ansible inventory file  #######################
data  "template_file" "inventory" {
    template = file("./templates/inventory.tpl")
    vars = {
      worker_host_name = join("\n", google_compute_instance.kube-worker.*.name)
    }
}

resource "local_file" "k8s_file" {
  content  = data.template_file.inventory.rendered
  filename = "./inventory/inventory.ini"
}

####################### create ansible extra vars file  #######################
data  "template_file" "extra_vars" {
  template = file("./templates/extra-vars.tpl")
  vars = {
    ansible_user = var.gce_ssh_user
    redis_cluster_name = var.redis_cluster_name
    redis_user_name = var.redis_user_name
    redis_pwd = var.redis_pwd
    redis_email_from = var.redis_email_from
    redis_smtp_host = var.redis_smtp_host
  }
}

resource "local_file" "extra_vars_file" {
  content  = data.template_file.extra_vars.rendered
  filename = "./inventory/boa-extra-vars.yaml"
}

###################### random id generator ####################################
resource "random_id" "id" {
  byte_length = 8
}


