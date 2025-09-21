variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}


variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "192.168.0.0/16"
}

variable "db_username" {
  description = "Master DB username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master DB password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}


variable "db_secret_name" {
  description = "Name for the DB credentials secret in AWS Secrets Manager"
  type        = string
  default     = "rds-db-credentials"
}
