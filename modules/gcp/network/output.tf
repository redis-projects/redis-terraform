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
