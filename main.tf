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
  name          = "${var.vpc}-public-subnet"
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.gce_public_subnet_cidr
}

resource "google_compute_subnetwork" "private-subnet" {
  name          = "${var.vpc}-private-subnet"
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.gce_private_subnet_cidr
}

resource "google_compute_router" "router" {
  name    = "${var.vpc}-router"
  region  = google_compute_subnetwork.private-subnet.region
  network = google_compute_network.vpc.self_link
  bgp {
    asn = 64514
  }
}


################################ nat  ############################

resource "google_compute_router_nat" "simple-nat" {
  name                               = "${var.vpc}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


################################ fire wall ############################


resource "google_compute_firewall" "private-firewall" {
  name    = "${var.vpc}-private-firewall"
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
  name    = "${var.vpc}-public-firewall"
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
  #count = var.bastion-ip-address-count
  #name  = "bastion-ip-address-${count.index}"
  name  = "${var.vpc}-bastion-ip-address"
}

resource "google_compute_instance" "bastion" {
  #count        = var.bastion-ip-address-count
  #name         = "bastion-${count.index}"
  name         = "${var.vpc}-bastion"
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

  metadata_startup_script = data.template_file.bastion_startup.rendered

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  provisioner "file" {
    content  = data.template_file.k8s.rendered
    destination = "/home/${var.gce_ssh_user}/boa-inventory.ini"

    connection {
      type        = "ssh"
      user        = var.gce_ssh_user
      private_key = file(var.gce_ssh_private_key_file)
      host        = google_compute_address.bastion-ip-address.address
    }
  }

  provisioner "file" {
    source  = "./templates/boa-extra-vars.yaml"
    destination = "/home/${var.gce_ssh_user}/boa-extra-vars.yaml"

    connection {
      type        = "ssh"
      user        = var.gce_ssh_user
      private_key = file(var.gce_ssh_private_key_file)
      host        = google_compute_address.bastion-ip-address.address
    }
  }

//  provisioner "remote-exec" {
//    inline = [
//      "export ANSIBLE_HOST_KEY_CHECKING=False",
//      "cd /home/${var.gce_ssh_user}/redis-ansible",
//      "ansible-playbook -i ./inventories/boa-cluster.ini redislabs-install.yaml -e @./extra_vars/boa-extra-vars.yaml -e @./group_vars/all/main.yaml -e re_url=${var.redis_distro}",
//      "ansible-playbook -i ./inventories/boa-cluster.ini redislabs-create-cluster.yaml -e @./extra_vars/boa-extra-vars.yaml -e @./group_vars/all/main.yaml"
//    ]
//
//    connection {
//      type        = "ssh"
//      user        = var.gce_ssh_user
//      private_key = file(var.gce_ssh_private_key_file)
//      host        = google_compute_address.bastion-ip-address.address
//    }
//  }
}

###################### redis nodes #################################

resource "google_compute_instance" "kube-worker" {
  count        = var.kube_worker_machine_count
  name         = "${var.vpc}-worker-${count.index}"
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

  metadata_startup_script = "sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config; systemctl restart sshd; yum -y update;"
}

####################### create ansible inventory file  #######################
data  "template_file" "k8s" {
    template = file("./templates/k8s.tpl")
    vars = {
      worker_host_name = join("\n", google_compute_instance.kube-worker.*.name)
      #worker_host_name = google_compute_instance.kube-worker.*.name
      #worker_ip = google_compute_instance.kube-worker.*.network_interface[0].access_config[0].nat_ip
      }
}

resource "local_file" "k8s_file" {
  content  = data.template_file.k8s.rendered
  filename = "./inventory/inventory.ini"
}


####################### create ssh files  ####################### 

data  "template_file" "ssh" {
    template = file("./templates/ssh.tpl")
    vars = {
        bastion_ip =  google_compute_address.bastion-ip-address.address
    }
}

resource "local_file" "ssh_file" {
  content  = data.template_file.ssh.rendered
  filename = "./scripts/ssh.sh"
}

data "template_file" "bastion_startup" {
  template = file("./templates/startup.tpl")
  vars = {
    redis_user = var.gce_ssh_user
  }
}


