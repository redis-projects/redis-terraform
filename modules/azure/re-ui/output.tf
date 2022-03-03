output "ui-ip" {
  value = length(var.ui_subnet) == 0 ? azurerm_public_ip.re-ui-ip[0].ip_address : azurerm_lb.re-ui-lb-internal[0].private_ip_address
}
