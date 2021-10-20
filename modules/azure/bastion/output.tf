output "bastion-public-ip-address" {
  value = azurerm_linux_virtual_machine.bastion.public_ip_address
}