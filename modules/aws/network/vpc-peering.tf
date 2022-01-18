# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = aws_vpc.vpc.id
  peer_vpc_id   = var.vpc_request_list[count.index]
  peer_region   = var.region_map[var.peer_request_list[count.index]]
  auto_accept   = false
  count         = length(var.vpc_request_list)

  tags = merge("${var.resource_tags}",{
    Side = "Peering Requestor"
  })
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = var.vpc_conn_index[count.index]
  auto_accept               = true
  count                     = length(var.vpc_conn_index)

  tags = merge("${var.resource_tags}",{
    Side = "Peering Accepter"
  })
}
