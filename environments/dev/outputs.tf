output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.compute.ec2_instance_id
}