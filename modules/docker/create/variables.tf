variable "ssh_user" {
  description = "User to ssh into"
  type        = string
}

variable "ssh_private_key_file" {
  description = "Path to SSH private key"
  type        = string
  sensitive   = true
}

variable "bastion_host" {
    description = "Docker host"
}

variable "servicenodes_private_ips" {
    description = "The service hosts IPs to install on"
}
