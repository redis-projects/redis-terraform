terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


############################################################
# VPC

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.name}-vpc"
  }
}


############################################################
# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}-igw"
  }
}


############################################################
# Subnets

resource "aws_subnet" "public-subnet-1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.name}-public-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-1" {
  count = length(var.private_subnet_cidr)
  vpc_id = aws_vpc.vpc.id
  cidr_block = values(var.private_subnet_cidr)[count.index]
  availability_zone = keys(var.private_subnet_cidr)[count.index]

  tags = {
    Name = "${var.name}-private-subnet-${count.index}"
  }
}


############################################################
# NAT Gateway

# Elastic IP for NAT Gateway
resource "aws_eip" "eip-nat" {
  vpc = true

  tags = {
    Name = "${var.name}.eip-nat"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip-nat.id
  subnet_id = aws_subnet.public-subnet-1.id

  tags = {
    Name = "${var.name}-nat-gateway"
  }
}


############################################################
# Route Tables

resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}-rt-public"
  }
}

resource "aws_route_table" "rt-private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}-rt-private"
  }
}

# Associate Public Subnet with Route Table for Internet Gateway
resource "aws_route_table_association" "rt-to-public-subnet" {
  subnet_id = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.rt-public.id
}

# Associate Private Subnet with Route Table
resource "aws_route_table_association" "rt-to-private-subnet" {
  count = length(var.private_subnet_cidr)
  subnet_id = aws_subnet.private-subnet-1[count.index].id
  route_table_id = aws_route_table.rt-private.id
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
  route_table_id         = aws_route_table.rt-private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private-allowipv6" {
  route_table_id              = aws_route_table.rt-private.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.igw.id
}

# Add route to the VPC of the peering request to routing table (private)
resource "aws_route" "private-req" {
  route_table_id            = aws_route_table.rt-private.id
  destination_cidr_block    = var.cidr_map[var.peer_request_list[count.index]]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer[count.index].id
  count                     = length(var.peer_request_list)
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
  route_table_id            = aws_route_table.rt-private.id
  destination_cidr_block    = var.cidr_map[var.peer_accept_list[count.index]]
  vpc_peering_connection_id = var.vpc_conn_index[count.index]
  count                     = length(var.peer_accept_list)
}

# Add route to the VPC of the peering accept to routing table (public)
resource "aws_route" "public-acc" {
  route_table_id            = aws_route_table.rt-public.id
  destination_cidr_block    = var.cidr_map[var.peer_accept_list[count.index]]
  vpc_peering_connection_id = var.vpc_conn_index[count.index]
  count                     = length(var.peer_accept_list)
}
