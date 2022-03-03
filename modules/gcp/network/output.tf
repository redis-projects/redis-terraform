output "vpc" {
  description = "The id of the VPC"
  value       = google_compute_network.vpc.id
}

output "private-subnet-name" {
  description = "The name of the private subnet"
  value       = google_compute_subnetwork.private-subnet.name
}

output "public-subnet-name" {
  description = "The name of the public subnet"
  value       = google_compute_subnetwork.public-subnet.name
}

output "ui-subnet" {
  description = "The UI Load Balancer subnets"
  value       = google_compute_subnetwork.ui-subnet
}

output "vpn_external_ip" {
  description = "External IP object of the Gateway Subnet for VPN traffic"
  value       = length(var.vpn_list) == 0 ? null : google_compute_address.gcp_vpn_ip[0].address
}

output "private_subnet_address_prefix" {
  description = "CIDR of the GCP private subnet"
  value       = google_compute_subnetwork.private-subnet.ip_cidr_range
}
