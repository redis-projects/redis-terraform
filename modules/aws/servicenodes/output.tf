output "servicenodes" {
  description = "The service nodes"
  value = aws_instance.node
  sensitive = true
}

output "servicenodes_private_ip" {
  description = "The private IP addresses of the service nodes"
  value = aws_instance.node.*.private_ip
  sensitive = false
}

output "servicenodes_public_ip" {
  description = "The public IP addresses of the service nodes"
  value = aws_eip.eip.*.public_ip
}
