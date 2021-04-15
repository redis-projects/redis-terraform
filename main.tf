provider "google" {
  credentials = file(var.credentials)
  project     = var.var_project
  region      = var.region
  zone        = var.zone
}

module "network" {
 source = "./modules/gcp/network"

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

module "bastion" {
 source = "./modules/gcp/bastion"

 vpc = var.vpc
 random_id = module.random_id.id.hex
 gce_public_subnet_cidr = var.gce_public_subnet_cidr
 gce_private_subnet_cidr = var.gce_private_subnet_cidr
 region = var.region
 public_subnet_name = module.network.public-subnet-name
 os = var.os
 boot_disk_size = var.boot_disk_size
 bastion_machine_type = var.bastion_machine_type
 gce_ssh_user = var.gce_ssh_user
 gce_ssh_pub_key_file = var.gce_ssh_pub_key_file
 inventory = data.template_file.inventory
 extra_vars = data.template_file.extra_vars
 gce_ssh_private_key_file = var.gce_ssh_private_key_file
 redis_distro = var.redis_distro
 ansible_repo_creds = var.ansible_repo_creds
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

