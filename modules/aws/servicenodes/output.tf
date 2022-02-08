output "servicenodes" {
  description = "The service nodes"
  value = aws_instance.node
  sensitive = true
}
