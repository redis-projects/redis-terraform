output "re-nodes" {
  description = "The Redis Enterprise nodes"
  value       = azurerm_linux_virtual_machine.redis
  sensitive   = true
}

output "dns-lb-name" {
  description = "DNS address of the Loadbalancer handling DNS"
  value       = azurerm_public_ip.re-dns-ip.fqdn
}