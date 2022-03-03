output "vpc" {
  description = "The id of the VPC"
  value       = aws_vpc.vpc.id 
}

output "raw_vpc" {
  description = "The raw VPC object"
  value       = aws_vpc.vpc 
}

output "private-subnet" {
  description = "The private subnets"
  value       = aws_subnet.private-subnet-1
}

output "public-subnet" {
  description = "The public subnets"
  value       = aws_subnet.public-subnet-1
}

output "lb-subnet" {
  description = "The Load Balancer subnets"
  value       = aws_subnet.lb-subnet
}

output "ui-subnet" {
  description = "The UI Load Balancer subnets"
  value       = aws_subnet.ui-subnet
}

output "public-private-security-groups" {
  description = "The ids of the private and public groups"
  value       = [aws_security_group.allow-local.id]
}

output "servicenode-security-group" {
  description = "The ids of the servicenode security groups"
  value       = [aws_security_group.servicenodes-sg.id]
}

output "private-security-groups" {
  description = "The id of the private groups"
  value       = [aws_security_group.allow-local.id]
}

output "public-security-groups" {
  description = "The id of the public groups"
  value       = [aws_security_group.allow-ssh.id]
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
  sensitive   = true
}

output "vpn_external_ip" {
  description = "AWS VPN public IP"
  value       = zipmap(local.gcp_azure_vpns_name,aws_vpn_connection.main)
  #value       = aws_vpn_connection.main
}
