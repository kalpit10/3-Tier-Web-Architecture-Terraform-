output "launch_template_id" {
  value       = aws_launch_template.this.id
  description = "Launch Template ID"
}

output "asg_name" {
  value       = aws_autoscaling_group.asg.name
  description = "Name of the Auto Scaling Group"
}

output "instance_ids" {
  value = aws_autoscaling_group.asg.*.id
}
