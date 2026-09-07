variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name used for resource naming and tagging"
  type        = string
}

variable "ec2_role_arn" {
  description = "ARN of the EC2 IAM role permitted to access the bucket"
  type        = string
}