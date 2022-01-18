output "vpc" {
  description = "The id of the VPC"
  value       = aws_vpc.vpc.id 
}

output "raw_vpc" {
  description = "The raw VPC object"
  value       = aws_vpc.vpc 
}

output "private-subnet" {
  description = "The id of the private subnets"
  value       = aws_subnet.private-subnet-1
}

output "public-subnet" {
  description = "The id of the public subnet"
  value       = aws_subnet.public-subnet-1.id 
}

output "public-private-security-groups" {
  description = "The ids of the private and public groups"
  value       = [aws_security_group.allow-local.id, aws_security_group.allow-ssh.id]
}

output "private-security-groups" {
  description = "The id of the private groups"
  value       = [aws_security_group.allow-local.id]
}

output "public-security-groups" {
  description = "The id of the public groups"
  value       = [aws_security_group.allow-ssh.id, aws_security_group.allow-crdb.id]
}

output "internet-gateway" {
  description = "Internet gateway entity"
  value       = aws_internet_gateway.igw 
}

output "peering-request-ids" {
  description = "map of Peering request IDs"
  value       = zipmap(var.peer_request_list, aws_vpc_peering_connection.peer.*.id)
}

output "vpn_connection" {
  description = "AWS VPN connection"
  value       = aws_vpn_connection.main 
}
