output "bastion-public-ip" {
  value = aws_eip.eip.public_ip
}
