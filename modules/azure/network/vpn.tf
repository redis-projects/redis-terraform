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

resource "azurerm_local_network_gateway" "lngw1" {
  name                = "${var.name}-LocalNetworkGateway1-${var.vpn_list[count.index]}"
  resource_group_name = "${var.resource_group}"
  location            = "${var.region}"
  gateway_address     = "${var.vpn_connections[count.index][0].tunnel2_address}"
  address_space       = ["${var.vpn_vpc_list[count.index].cidr_block}"]
  count               = length(var.vpn_list)
}

resource "azurerm_local_network_gateway" "lngw2" {
  name                = "${var.name}-LocalNetworkGateway2-${var.vpn_list[count.index]}"
  resource_group_name = "${var.resource_group}"
  location            = "${var.region}"
  gateway_address     = "${var.vpn_connections[count.index][0].tunnel1_address}"
  address_space       = ["${var.vpn_vpc_list[count.index].cidr_block}"]
  count               = length(var.vpn_list)
}

resource "azurerm_virtual_network_gateway_connection" "vngc1" {
  name                = "${var.name}-VirtualNetworkConnection1-${var.vpn_list[count.index]}"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"
  count               = length(var.vpn_list)

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.vng[0].id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.lngw1[count.index].id}"

  shared_key = "${var.vpn_connections[count.index][0].tunnel2_preshared_key}"
}

resource "azurerm_virtual_network_gateway_connection" "vngc2" {
  name                = "${var.name}-VirtualNetworkConnection2-${var.vpn_list[count.index]}"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"
  count               = length(var.vpn_list)

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.vng[0].id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.lngw2[count.index].id}"

  shared_key = "${var.vpn_connections[count.index][0].tunnel1_preshared_key}"
}


resource "azurerm_route_table" "route" {
  name                = "${var.name}-VpnRouteTable-${var.vpn_list[count.index]}"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group}"
  count               = length(var.vpn_list)

  route {
    name           = "${var.name}-VpnRoute-${var.vpn_list[count.index]}"
    address_prefix = "${var.vpn_vpc_list[count.index].cidr_block}"
    next_hop_type  = "VirtualNetworkGateway"
  }

}