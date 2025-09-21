variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "key_name" {
  type        = string
  description = "SSH key pair name"
}

variable "app_sg_id" {
  type        = string
  description = "Security Group ID for app servers"
}

variable "desired_capacity" {
  default     = 2
  description = "Initial number of instances"
}

variable "min_size" {
  default     = 2
  description = "Minimum number of instances"
}

variable "max_size" {
  default     = 6
  description = "Maximum number of instances"
}

variable "private_subnet_ids" {
  description = "List of private app subnet IDs for ASG"
  type        = list(string)
}

variable "target_group_arns" {
  description = "ARNs of the ALB Target Groups"
  type        = list(string)
}

variable "cloudwatch_agent_config" {
  type        = string
  description = "Rendered CloudWatch Agent JSON config"
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM Instance Profile"
  type        = string
}

variable "DB_HOST" {
  description = "RDS endpoint hostname for DB connection"
  type        = string
}
