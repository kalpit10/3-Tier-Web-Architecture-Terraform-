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

output "private_key_pem" {
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = false
  description = "Private key for SSH access inside EC2 instances"
}

output "key_name" {
  value = aws_key_pair.generated_key.key_name
}
