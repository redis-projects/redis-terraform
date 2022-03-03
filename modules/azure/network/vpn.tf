locals {
  aws_vpn = flatten([
    for vpn in var.aws_vpns : [
      for cidr in vpn.cidr_list : {
        name = vpn.name
        cidr = cidr
      }
    ]
  ])
}

# First, create the special "GatewaySubnet" for VPN connections
resource "azurerm_subnet" "GatewaySubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${var.resource_group}"
  virtual_network_name = azurerm_virtual_network.vpc.name
  address_prefixes     = ["${var.gateway_subnet_cidr}"]
  count                = min(length(var.vpn_list),1)
}

resource "azurerm_public_ip" "gwpip" {
  name                    = "${var.name}-GatewaySubnet-IP"
  location                = "${var.region}"
  resource_group_name     = "${var.resource_group}"
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
  count                   = min(length(var.vpn_list),1)
}

resource "azurerm_virtual_network_gateway" "vng" {
  name                = "${var.name}-VirtualNetworkGateway"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"
  count               = min(length(var.vpn_list),1)

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "${var.name}-VirtualNetworkGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.gwpip[0].id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.GatewaySubnet[0].id}"
  }

}

resource "azurerm_local_network_gateway" "lngw" {
  name                = "${var.name}-LocalNetworkGateway-${var.gcp_azure_vpns[count.index].name}"
  resource_group_name = "${var.resource_group}"
  location            = "${var.region}"
  gateway_address     = "${var.gcp_azure_vpns[count.index].external_ip}"
  address_space       = ["${var.gcp_azure_vpns[count.index].cidr}"]
  count               = length(var.gcp_azure_vpns)
}
resource "azurerm_local_network_gateway" "lngw1" {
  name                = "${var.name}-LocalNetworkGateway1-${var.aws_vpns[count.index].name}"
  resource_group_name = "${var.resource_group}"
  location            = "${var.region}"
  gateway_address     = "${var.aws_vpns[count.index].external_ip[var.vnet_name].tunnel1_address}"
  address_space       = "${var.aws_vpns[count.index].cidr_list}"
  count               = length(var.aws_vpns)
}

resource "azurerm_local_network_gateway" "lngw2" {
  name                = "${var.name}-LocalNetworkGateway2-${var.aws_vpns[count.index].name}"
  resource_group_name = "${var.resource_group}"
  location            = "${var.region}"
  gateway_address     = "${var.aws_vpns[count.index].external_ip[var.vnet_name].tunnel2_address}"
  address_space       = "${var.aws_vpns[count.index].cidr_list}"
  count               = length(var.aws_vpns)
}

resource "azurerm_virtual_network_gateway_connection" "vngc" {
  name                = "${var.name}-VirtualNetworkConnection-${var.gcp_azure_vpns[count.index].name}"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"
  count               = length(var.gcp_azure_vpns)

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.vng[0].id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.lngw[count.index].id}"

  shared_key = "${var.gcp_azure_vpns[count.index].secret_key}"
}

resource "azurerm_virtual_network_gateway_connection" "vngc1" {
  name                = "${var.name}-VirtualNetworkConnection1-${var.aws_vpns[count.index].name}"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"
  count               = length(var.aws_vpns)

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.vng[0].id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.lngw1[count.index].id}"

  shared_key = "${var.aws_vpns[count.index].secret_key}"
}

resource "azurerm_virtual_network_gateway_connection" "vngc2" {
  name                = "${var.name}-VirtualNetworkConnection2-${var.aws_vpns[count.index].name}"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"
  count               = length(var.aws_vpns)

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.vng[0].id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.lngw2[count.index].id}"

  shared_key = "${var.aws_vpns[count.index].secret_key}"
}

resource "azurerm_route_table" "routeA" {
  name                = "${var.name}-VpnRouteTableA-${var.gcp_azure_vpns[count.index].name}"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"
  count               = length(var.gcp_azure_vpns)

  route {
    name           = "${var.name}-VpnRoute-${var.gcp_azure_vpns[count.index].name}"
    address_prefix = "${var.gcp_azure_vpns[count.index].cidr}"
    next_hop_type  = "VirtualNetworkGateway"
  }

}

resource "azurerm_route_table" "routeB" {
  name                = "${var.name}-VpnRouteTableB-${local.aws_vpn[count.index].name}-${count.index}"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"
  count               = length(local.aws_vpn)

  route {
    name           = "${var.name}-VpnRoute-${local.aws_vpn[count.index].name}-${count.index}"
    address_prefix = "${local.aws_vpn[count.index].cidr}"
    next_hop_type  = "VirtualNetworkGateway"
  }

}
