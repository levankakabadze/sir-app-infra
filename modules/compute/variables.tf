variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name used for resource naming and tagging"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "Map of public subnet IDs keyed by AZ suffix — for ALB"
  type        = map(string)
}

variable "private_subnet_ids" {
  description = "Map of private subnet IDs keyed by AZ suffix — for EC2"
  type        = map(string)
}

variable "alb_sg_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "app_sg_id" {
  description = "ID of the application security group"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

