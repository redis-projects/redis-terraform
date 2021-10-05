variable "ssh_user" {
  description = "User to ssh into"
  type        = string
}

variable "ssh_private_key_file" {
  description = "Path to SSH private key"
  type        = string
  sensitive   = true
}

variable "inventory" {
  description = "Redis enterprise inventory"
  default     = ""
}

variable "extra_vars" {
  description = "Redis enterprise extra variables"
  default     = ""
}

variable "host" {
    description = "Bastion host"
}

variable "redis_distro" {
  description = "Redis distribution"
  type        = string
}