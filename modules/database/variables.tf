variable "project" {
    description = "Project name used for resource naming"
    type        = string
}

variable "environment" {
    description = "Environment name used for resource naming and tagging"
    type        = string
}

variable "isolated_subnet_ids" {
  description = "Map of isolated subnet IDs keyed by AZ suffix - for RDS"
  type        = map(string)
}

variable "db_sg_id" {
  description = "Security group ID for the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Name of the initial DB to create"
  type        = string
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
}

variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}
