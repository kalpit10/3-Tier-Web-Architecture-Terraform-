variable "ami_id" {
  description = "AMI ID for the bastion host"
  type        = string
}

variable "instance_type" {
  description = "Instance type for bastion (e.g., t2.micro)"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID where bastion will be launched"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security group ID for bastion host"
  type        = string
}
