variable "db_subnet_ids" {
  description = "List of private DB subnet IDs for RDS"
  type        = list(string)
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_sg_id" {
  description = "Security group ID for RDS"
  type        = string
}