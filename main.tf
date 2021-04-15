provider "google" {
  credentials = file(var.credentials)
  project     = var.var_project
  region      = var.region
  zone        = var.zone
}

module "network" {
 source = "./modules/network"

 vpc = var.vpc
 random_id = module.random_id.id.hex
 gce_public_subnet_cidr = var.gce_public_subnet_cidr
 gce_private_subnet_cidr = var.gce_private_subnet_cidr
 region = var.region
}

module "random_id" {
 source = "./modules/random_id"
}

########################### bastion ############################ 




resource "google_compute_address" "bastion-ip-address" {
  name  = "${var.vpc}-${module.random_id.id.hex}-bastion-ip-address"
}

resource "google_compute_instance" "bastion" {
  name         = "${var.vpc}-${module.random_id.id.hex}-bastion"
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
    subnetwork = module.network.public-subnet-name

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
  name         = "${var.vpc}-${module.random_id.id.hex}-worker-${count.index}"
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
    subnetwork = module.network.private-subnet-name
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

