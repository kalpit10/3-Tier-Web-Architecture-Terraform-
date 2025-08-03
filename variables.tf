variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}


variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "192.168.0.0/16"
}


variable "db_username" {

}

variable "db_password" {

}