variable "credentials" {
  default = "./terraform_account.json"
}

variable "var_project" {
  default = "redislabs-sa-training-services"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "os" {
  default = "rhel-sap-cloud/rhel-7-6-sap-v20210217"
  #default = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable "redis_distro" {
  default = "https://s3.amazonaws.com/redis-enterprise-software-downloads/6.0.6/redislabs-6.0.6-39-rhel7-x86_64.tar"
}

variable "redis_cluster_name" {
  default = "boa.rlabs.org"
}

variable "redis_user_name" {
  default = "admin@admin.com"
}

variable "redis_pwd" {
  default = "admin"
}

variable "redis_email_from" {
  default = "admin@domain.tld"
}

variable "redis_smtp_host" {
  default = "smtp.domain.tld"
}

variable "vpc" {
  default = "boatest"
}

variable "gce_ssh_user" {
  default = "redislabs"
}

variable "gce_ssh_pub_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

variable "gce_ssh_private_key_file" {
  default = "~/.ssh/id_rsa"
}

variable "gce_public_subnet_cidr" {
  default = "10.1.0.0/24"
}

variable "gce_private_subnet_cidr" {
  default = "10.2.0.0/16"
}

variable "bastion-ip-address-count" {
  default = 1
}


variable "boot_disk_size" {
  default = 50
}


######  machine count ######
variable "kube_worker_machine_count" {
  default = 3
}

######  machine count ends ######

variable "kube_master_machine_type" {
  default = "n1-standard-4"
}



variable "bastion_machine_type" {
  default = "n1-standard-1"
}

variable "kube_ingress_machine_type" {
  default = "n1-standard-2"
}


variable "kube_worker_machine_type" {
  default = "n1-standard-4"
}



variable "kube_storage_machine_type" {
  default = "n1-standard-4"
}

variable "kube_storage_disk_size" {
  default = 500
}

variable "kube_storage_disk_type" {
  #default = "pd-standard"
  default = "pd-ssd"
}

###### the repo creds are of the user_id:password format ####
variable "ansible_repo_creds" {
  #replace the following with your credentials
  default = "xxxxxx:yyyyyyy"
}

