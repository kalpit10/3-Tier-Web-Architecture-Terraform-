output "bastion_public_ip" {
  value       = module.bastion.bastion_public_ip
  description = "Public IP of the Bastion Host"
}

output "bastion_instance_id" {
  value       = module.bastion.bastion_instance_id
  description = "Instance ID of the Bastion Host"
}

output "asg_name" {
  value       = module.asg.asg_name
  description = "Name of the Auto Scaling Group"
}

output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "The public DNS name of the Application Load Balancer"
}


output "rds_endpoint" {
  value       = module.rds.rds_endpoint
  description = "RDS Endpoint"
}

output "ec2_private_key" {
  value     = module.security.private_key_pem
  sensitive = true
}

output "iam_instance_profile_name" {
  value       = module.iam.iam_instance_profile_name
  description = "Name of the IAM Instance Profile"
}

output "db_secret_arn" {
  description = "ARN of the DB credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.arn
}
output "db_secret_name" {
  description = "Name of the DB credentials secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "gha_role_arn" {
  value       = module.iam.gha_role_arn
  description = "ARN of the GitHub Actions IAM Role"
}
