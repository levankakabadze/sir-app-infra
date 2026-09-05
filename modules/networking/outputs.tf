output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs keyed by AZ suffix"
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  description = "Map of private subnet IDs keyed by AZ suffix"
  value       = { for k, v in aws_subnet.private : k => v.id }
}

output "isolated_subnet_ids" {
  description = "Map of isolated subnet IDs keyed by AZ suffix"
  value       = { for k, v in aws_subnet.isolated : k => v.id }
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

