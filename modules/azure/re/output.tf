output "re-public-ips" {
  value = azurerm_public_ip.redis-public-ip
}

output "re-nodes" {
  description = "The Redis Enterprise nodes"
  value       = azurerm_linux_virtual_machine.redis
  sensitive   = true
}