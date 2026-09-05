variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR block for the public subnet, keyed by AZ suffix"
  type        = map(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR block for the private subnet, keyed by AZ suffix"
  type        = map(string)
}

variable "isolated_subnet_cidrs" {
  description = "CIDR block for the isolated subnet, keyed by AZ suffix"
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