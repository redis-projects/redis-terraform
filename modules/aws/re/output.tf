output "re-nodes" {
  description = "The Redis Enterprise nodes"
  value = aws_instance.node
  sensitive = true
}

output "re-public-ips" {
  description = "IP addresses of all Redis cluster nodes"
  value       = aws_eip.eip
}
