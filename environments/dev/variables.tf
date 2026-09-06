variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR block for the public subnets, keyed by AZ suffix"
  type        = map(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR block for the private subnets, keyed by AZ suffix"
  type        = map(string)
}

variable "isolated_subnet_cidrs" {
  description = "CIDR block for the isolated subnets, keyed by AZ suffix"
  type        = map(string)
}

variable "environment" {
  description = "The environment name used for resource naming and tagging"
  type        = string
}

variable "project" {
  description = "The project name used for resource naming"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}