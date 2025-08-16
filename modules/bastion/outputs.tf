output "bastion_instance_id" {
  value       = aws_instance.this.id
  description = "ID of the bastion instance"
}

output "bastion_public_ip" {
  value       = aws_instance.this.public_ip
  description = "Public IP of the bastion instance"
}
