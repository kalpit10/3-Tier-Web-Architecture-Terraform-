output "rds_endpoint" {
  value       = aws_db_instance.this.endpoint
  description = "RDS MYSQL endpoint"
}