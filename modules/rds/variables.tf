variable "db_subnet_ids" {
  description = "List of private DB subnet IDs for RDS"
  type        = list(string)
}

variable "db_secret_arn" {
  description = "ARN of the DB secret in Secrets Manager"
  type        = string
}


variable "db_sg_id" {
  description = "Security group ID for RDS"
  type        = string
}
