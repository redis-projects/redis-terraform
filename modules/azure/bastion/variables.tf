variable "name" {
  description = "Combined name of the deployment and VPC: <DEPLOYMENT>-<VPC>"
  type        = string
}
variable "region" {
  description = "Region for the VCP/VNET deployment"
  type        = string
}
variable "resource_group" {
  description = "Azure resourcegroup for the deployment"
  type        = string
}

variable "public_subnet_id" {
  description = "Object for the public subnet"
  type        = string
}

variable "public_secgroup" {
  description = "list of security group IDs for the public subnet"
  type        = list
}

variable "bastion_machine_type" {
  description = "Hardware type bastion node"
  type        = string    
}

variable "os" {
  description = "Machine image (OS)"
  type        = string    
}

variable "bastion_machine_plan" {
  description = "Azure OS image plan (Marketplace)"
  type        = string    
}

variable "ssh_user" {
  description = "root user for bastion node"
  type        = string
}

variable "ssh_pub_key_file" {
  description = "Public key of the Bastion root user"
  type        = string
}

