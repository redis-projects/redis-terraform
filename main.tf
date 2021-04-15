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
 subnet = module.network.public-subnet-name
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

module "re" {
 source = "./modules/gcp/re"

 vpc = var.vpc
 random_id = module.random_id.id.hex
 kube_worker_machine_count = var.kube_worker_machine_count
 kube_worker_machine_type = var.kube_worker_machine_type
 boot_disk_size = var.boot_disk_size
 os = var.os
 subnet = module.network.private-subnet-name
 gce_ssh_user = var.gce_ssh_user
 gce_ssh_pub_key_file = var.gce_ssh_pub_key_file
}

####################### create ansible inventory file  #######################
data  "template_file" "inventory" {
    template = file("./templates/inventory.tpl")
    vars = {
      worker_host_name = join("\n", module.re.re-nodes.*.name)
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

