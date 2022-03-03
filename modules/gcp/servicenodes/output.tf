output "servicenodes" {
  description = "The Service nodes"
  value       = google_compute_instance.node
  sensitive   = true
}

output "servicenodes_private_ip" {
  description = "The private IP addresses of the service nodes"
  value       = google_compute_instance.node.*.name
  sensitive = false
}

output "servicenodes_public_ip" {
  description = "The public IP addresses of the service nodes"
  value = google_compute_address.servicenodes-ip-address.*.address
}
