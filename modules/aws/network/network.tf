terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

locals {
  private-req-list = flatten([
    for rt-private-id in aws_route_table.rt-private.*.id : [
      for peer_conn in aws_vpc_peering_connection.peer.*.id : {
        vpc_peering_connection_id = peer_conn
        destination_cidr_block    = var.cidr_map[var.peer_request_list[index(aws_vpc_peering_connection.peer.*.id ,peer_conn)]]
        route_table_id            = rt-private-id
      }
    ]
  ])
  private-acc-list = flatten([
    for rt-private-id in aws_route_table.rt-private.*.id : [
      for peer_conn in var.vpc_conn_index : {
        vpc_peering_connection_id = peer_conn
        destination_cidr_block    = var.cidr_map[var.peer_accept_list[index(var.vpc_conn_index ,peer_conn)]]
        route_table_id            = rt-private-id
      }
    ]
  ])
}

############################################################
# VPC

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = merge("${var.resource_tags}",{
    Name = "${var.resource_name}"
  })  
}


############################################################
# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-igw"
  })
}


############################################################
# Subnets

resource "aws_subnet" "public-subnet-1" {
  count = length(var.public_subnet_cidr)
  vpc_id = aws_vpc.vpc.id
  cidr_block = values(var.public_subnet_cidr)[count.index]
  availability_zone = keys(var.public_subnet_cidr)[count.index]

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-public-subnet-${count.index}"
  })
}

resource "aws_subnet" "private-subnet-1" {
  count = length(var.private_subnet_cidr)
  vpc_id = aws_vpc.vpc.id
  cidr_block = values(var.private_subnet_cidr)[count.index]
  availability_zone = keys(var.private_subnet_cidr)[count.index]

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-private-subnet-${count.index}"
  })
}

resource "aws_subnet" "lb-subnet" {
  count = length(var.lb_subnet_cidr)
  vpc_id = aws_vpc.vpc.id
  cidr_block = values(var.lb_subnet_cidr)[count.index]
  availability_zone = keys(var.lb_subnet_cidr)[count.index]

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-lb-subnet-${count.index}"
  })
}


############################################################
# NAT Gateway

# Elastic IP for NAT Gateway
resource "aws_eip" "eip-nat" {
  count = length(var.lb_subnet_cidr)
  vpc = true

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-eip-nat-${count.index}"
  })
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  count = length(var.lb_subnet_cidr)
  allocation_id = aws_eip.eip-nat[count.index].id
  subnet_id = aws_subnet.lb-subnet[count.index].id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-nat-gateway-${count.index}"
  })
}


############################################################
# Route Tables

resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-rt-public"
  })
}

resource "aws_route_table" "rt-private" {
  count = length(var.private_subnet_cidr)
  vpc_id = aws_vpc.vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-rt-private-${count.index}"
  })
}

resource "aws_route_table" "rt-lb" {
  vpc_id = aws_vpc.vpc.id

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-rt-lb"
  })
}

# Associate Public Subnets with Route Table for Internet Gateway
resource "aws_route_table_association" "rt-to-public-subnet" {
  count = length(var.public_subnet_cidr)
  subnet_id = aws_subnet.public-subnet-1[count.index].id
  route_table_id = aws_route_table.rt-public.id
}

# Associate Private Subnets with Route Table
resource "aws_route_table_association" "rt-to-private-subnet" {
  count = length(var.private_subnet_cidr)
  subnet_id = aws_subnet.private-subnet-1[count.index].id
  route_table_id = aws_route_table.rt-private[count.index].id
}

resource "aws_route_table_association" "rt-to-lb-subnet" {
  count = length(var.lb_subnet_cidr)
  subnet_id = aws_subnet.lb-subnet[count.index].id
  route_table_id = aws_route_table.rt-lb.id
}

############################################################
# Route Entries

resource "aws_route" "public-allipv4" {
  route_table_id         = aws_route_table.rt-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "public-allowipv6" {
  route_table_id              = aws_route_table.rt-public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.igw.id
}

resource "aws_route" "private-allipv4" {
  count                  = length(var.private_subnet_cidr)
  route_table_id         = aws_route_table.rt-private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway[count.index].id
}

#resource "aws_route" "private-allowipv6" {
#  count                       = length(var.private_subnet_cidr)
#  route_table_id              = aws_route_table.rt-private[count.index].id
#  destination_ipv6_cidr_block = "::/0"
#  gateway_id                  = aws_nat_gateway.nat_gateway[count.index].id
#}

resource "aws_route" "lb-allipv4" {
  route_table_id         = aws_route_table.rt-lb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "lb-allowipv6" {
  route_table_id              = aws_route_table.rt-lb.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.igw.id
}

# Add route to the VPC of the peering request to routing table (private)
resource "aws_route" "private-req" {
  route_table_id            = local.private-req-list[count.index].route_table_id
  destination_cidr_block    = local.private-req-list[count.index].destination_cidr_block
  vpc_peering_connection_id = local.private-req-list[count.index].vpc_peering_connection_id
  count                     = length(var.peer_request_list)*length(var.private_subnet_cidr)
}

# Add route to the VPC of the peering request to routing table (public)
resource "aws_route" "public-req" {
  route_table_id            = aws_route_table.rt-public.id
  destination_cidr_block    = var.cidr_map[var.peer_request_list[count.index]]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer[count.index].id
  count                     = length(var.peer_request_list)
}

# Add route to the VPC of the peering accept to routing table (private)
resource "aws_route" "private-acc" {
  route_table_id            = local.private-acc-list[count.index].route_table_id
  destination_cidr_block    = local.private-acc-list[count.index].destination_cidr_block
  vpc_peering_connection_id = local.private-acc-list[count.index].vpc_peering_connection_id
  count                     = length(var.vpc_conn_index)*length(var.private_subnet_cidr)
}

# Add route to the VPC of the peering accept to routing table (public)
resource "aws_route" "public-acc" {
  route_table_id            = aws_route_table.rt-public.id
  destination_cidr_block    = var.cidr_map[var.peer_accept_list[count.index]]
  vpc_peering_connection_id = var.vpc_conn_index[count.index]
  count                     = length(var.peer_accept_list)
}
