variable "cluster_fqdn" {
  description = "Fully Qualified Domain Name of the cluster"
  type        = string
}

variable "parent_zone" {
  description = "Parent Zone where the record get added"
  type        = string
}

variable "ip_addresses" {
  description = "List of Public (!) IP addresses for each cluster node"
  type        = list
}

variable "name" {
  description = "Name of the entry"
  type        = string
}