output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Map of all subnet IDs"
  value       = { for k, v in aws_subnet.subnets : k => v.id }
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

output "security_group_id" {
  description = "ID of the main security group"
  value       = aws_security_group.main.id
}