locals {
  remote_route_list = flatten([
    for rt-private-id in aws_route_table.rt-private.*.id : [
      for peer in var.gcp_azure_vpns : {
        destination_cidr_block    = peer.cidr
        route_table_id            = rt-private-id
      }
    ]
  ])
  gcp_azure_vpns_name = [for vpn in var.gcp_azure_vpns: vpn.name]
}

# create customer gateway
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = "${var.gcp_azure_vpns[count.index].external_ip}"
  type       = "ipsec.1"
  count      = length(var.gcp_azure_vpns)

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-CustomerGateway-${var.gcp_azure_vpns[count.index].name}"
  })
  #depends_on = [var.gcp_azure_vpns]
}

# create virtual private gateway
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = aws_vpc.vpc.id
  count  = min(length(var.gcp_azure_vpns),1)

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-VirtualPrivateGateway"
  })
}

# create vpn connection
resource "aws_vpn_connection" "main" {
  vpn_gateway_id        = "${aws_vpn_gateway.vpn_gw[0].id}"
  customer_gateway_id   = "${aws_customer_gateway.main[count.index].id}"
  type                  = "ipsec.1"
  static_routes_only    = true
  tunnel1_preshared_key = var.gcp_azure_vpns[count.index].secret_key
  tunnel2_preshared_key = var.gcp_azure_vpns[count.index].secret_key
  count                 = length(var.gcp_azure_vpns)
  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-AWS-VPN-connection-${count.index}"
  })
}

# Create vpn connection route to remote site
resource "aws_vpn_connection_route" "remote" {
  destination_cidr_block = "${var.gcp_azure_vpns[count.index].cidr}"
  vpn_connection_id      = "${aws_vpn_connection.main[count.index].id}"
  count                  = length(var.gcp_azure_vpns)
}

# Create AWS to remote Route
resource "aws_route" "remoteroute" {
  route_table_id            = local.remote_route_list[count.index].route_table_id
  destination_cidr_block    = local.remote_route_list[count.index].destination_cidr_block
  gateway_id                = "${aws_vpn_gateway.vpn_gw[0].id}"
  count                     = length(var.gcp_azure_vpns)*length(aws_route_table.rt-private)
}
