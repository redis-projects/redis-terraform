output "re-nodes" {
  description = "The Redis Enterprise nodes"
  value       = google_compute_instance.node
  sensitive   = true
}
