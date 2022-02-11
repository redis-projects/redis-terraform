output "servicenodes" {
  description = "The service nodes"
  value       = azurerm_linux_virtual_machine.service
  sensitive   = true
}

output "servicenodes_private_ip" {
  description = "The private IP addresses of the service nodes"
  value       = azurerm_linux_virtual_machine.service.*.private_ip_address
  sensitive = false
}

output "servicenodes_public_ip" {
  description = "The public IP addresses of the service nodes"
  value = azurerm_linux_virtual_machine.service.*.public_ip_address
}