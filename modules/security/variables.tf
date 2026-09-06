variable "vpc_id" {
  description = "The ID of the VPC where the security group will be created."
  type        = string
}

variable "environment" {
  description = "Environment name used for resource naming and tagging"
  type        = string
}

variable "project" {
  description = "Project name used for resource naming"
  type        = string
}