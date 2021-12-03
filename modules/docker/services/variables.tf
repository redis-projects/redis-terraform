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

variable "host" {
    description = "Docker host"
}

variable "start_script" {
    description = "Start up script"
}