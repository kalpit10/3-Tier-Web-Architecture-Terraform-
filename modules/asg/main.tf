resource "aws_launch_template" "this" {
  name_prefix   = "final-project-lt-v8"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.app_sg_id]

  user_data = base64encode(templatefile("${path.module}/../../user-data.sh", {
    cloudwatch_agent_config = var.cloudwatch_agent_config
  }))

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "final-project-app-template"
    }
  }
}


resource "aws_autoscaling_group" "asg" {
  name                      = "final-project-asg"
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  vpc_zone_identifier       = var.private_subnet_ids # These are the private app subnet IDs (passed from root)
  target_group_arns         = var.target_group_arns  # Automatically add EC2s launched by ASG inside TG
  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key   = "Name" # Applies a name tag to all launched instances
    value = "final-project-app-instance"
    # When propagate_at_launch is set to true for a specific tag, that tag is automatically added to any new instances launched by the ASG.
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "App"
    propagate_at_launch = true
  }
}
