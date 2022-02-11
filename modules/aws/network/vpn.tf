# create customer gateway
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = "${var.vpn_external_ips[count.index][0].ip_address}"
  type       = "ipsec.1"
  count      = length(var.vpn_list)

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-CustomerGateway-${var.vpn_list[count.index]}"
  })
  depends_on = [var.vpn_external_ips]
}

# create virtual private gateway
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = aws_vpc.vpc.id
  count  = min(length(var.vpn_list),1)

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-VirtualPrivateGateway"
  })
}

# create vpn connection
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw[0].id}"
  customer_gateway_id = "${aws_customer_gateway.main[count.index].id}"
  type                = "ipsec.1"
  static_routes_only  = true
  count               = length(var.vpn_list)
  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-AWS-VPN-connection-${count.index}"
  })
}

# Create vpn connection route to remote site
resource "aws_vpn_connection_route" "remote" {
  destination_cidr_block = "${var.private_subnet_list[count.index]}"
  vpn_connection_id      = "${aws_vpn_connection.main[count.index].id}"
  count                  = length(var.vpn_list)
}

# Create AWS to remote Route
#resource "aws_route" "remoteroute" {
#  route_table_id            = aws_route_table.rt-private.id
#  destination_cidr_block    = "${var.private_subnet_list[count.index]}"
#  gateway_id                = "${aws_vpn_gateway.vpn_gw[0].id}"
#  count                     = length(var.vpn_list)
#}
