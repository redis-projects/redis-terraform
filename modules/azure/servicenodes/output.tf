output "servicenodes" {
  description = "The service nodes"
  value       = azurerm_linux_virtual_machine.service
  sensitive   = true
}
