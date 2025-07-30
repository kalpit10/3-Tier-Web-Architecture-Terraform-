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
