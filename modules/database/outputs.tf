output "db_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_name" {
  description = "The name of the initial database created in the RDS instance"
  value       = aws_db_instance.main.db_name
}

output "db_port" {
  description = "The port on which the RDS instance is listening"
  value       = aws_db_instance.main.port
}