variable "ssh_user" {
  description = "User to ssh into"
  type        = string
}

variable "ssh_private_key_file" {
  description = "Path to SSH private key"
  type        = string
  sensitive   = true
}

variable "host" {
    description = "Docker host"
}
