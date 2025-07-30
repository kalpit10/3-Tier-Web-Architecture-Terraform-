output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  # k = subnet name
  # subnet.id => subnet's id, so subnet-name = subnet's id
  # We can then access it only by calling the subent name to get the subnet id
  value = {for k , subnet in aws_subnet.all : k => subnet.id}
}

