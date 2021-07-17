output "re-nodes" {
  description = "The Redis Enterprise nodes"
  value = aws_instance.node
  sensitive = true
}
