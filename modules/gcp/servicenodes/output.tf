output "servicenodes" {
  description = "The Service nodes"
  value       = google_compute_instance.node
  sensitive   = true
}
