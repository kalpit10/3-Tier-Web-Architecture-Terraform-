output "bastion_sg_id" {
  value       = aws_security_group.bastion.id
  description = "Security Group ID for Bastion Host"
}

output "alb_sg_id" {
  description = "Security group ID of Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "Security group for web servers"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "Security group for RDS"
  value       = aws_security_group.db.id
}