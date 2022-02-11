output "re-nodes" {
  description = "The Redis Enterprise nodes"
  value       = google_compute_instance.node
  sensitive   = true
}

output "re-public-ips" {
  description = "IP addresses of all Redis cluster nodes"
  value       = google_compute_address.cluster-ip-address.*.address
}
