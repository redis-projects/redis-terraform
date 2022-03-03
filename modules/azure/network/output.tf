output "public-subnet" {
  description = "The ID of the public subnet"
  value       = azurerm_subnet.public-subnet.id
}

output "private-subnet" {
  description = "The ID of the private subnet"
  value       = azurerm_subnet.private-subnet.id
}

output "ui-subnet" {
  description = "The UI Load Balancer subnets"
  value       = azurerm_subnet.ui-subnet
}

output "private_subnet_address_prefix" {
  description = "The address prefix of the private subnet"
  value       = azurerm_subnet.private-subnet.address_prefix
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

output "raw_vnet" {
  description = "The Azure virtual network"
  value       = azurerm_virtual_network.vpc
}

output "vpn_external_ip" {
  description = "External IP object of the Gateway Subnet for VPN traffic"
  value       = length(var.vpn_list) == 0 ? null : azurerm_public_ip.gwpip[0].ip_address
}
