resource "azurerm_virtual_network_peering" "peer-request" {
  count                        = length(var.vpc_request_list)
  name                         = "${var.name}-peer-request-${count.index}"
  resource_group_name          = var.resource_group
  virtual_network_name         = azurerm_virtual_network.vpc.name
  remote_virtual_network_id    = var.vpc_request_list[count.index]
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit = false
}

resource "azurerm_virtual_network_peering" "peer-accept" {
  count                        = length(var.vpc_accept_list)
  name                         = "${var.name}-peer-accept-${count.index}"
  resource_group_name          = var.resource_group
  virtual_network_name         = azurerm_virtual_network.vpc.name
  remote_virtual_network_id    = var.vpc_accept_list[count.index]
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  # `allow_gateway_transit` must be set to false for vnet Global Peering
  allow_gateway_transit = false
}