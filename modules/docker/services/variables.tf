variable "ssh_user" {
  description = "User to ssh into"
  type        = string
}

variable "ssh_private_key_file" {
  description = "Path to SSH private key"
  type        = string
  sensitive   = true
}

variable "contents" {
  description = "Content to push to docker host"
}

variable "servicenodes" {
    description = "The service hosts to install on"
}

variable "start_script" {
    description = "Start up script"
}

variable "bastion_host" {
    description = "Docker host"
}