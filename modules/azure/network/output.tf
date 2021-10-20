output "public-subnet" {
  description = "The ID of the public subnet"
  value       = azurerm_subnet.public-subnet.id
}

output "private-subnet" {
  description = "The ID of the private subnet"
  value       = azurerm_subnet.private-subnet.id
}

output "public-security-groups" {
  description = "The id of the public groups"
  value       = [azurerm_network_security_group.allow-ssh.id]
}

output "private-security-groups" {
  description = "The id of the private security groups"
  value       = [azurerm_network_security_group.allow-local.id]
}

output "vpc" {
  description = "The id of the Azure virtual network"
  value       = azurerm_virtual_network.vpc.id
}