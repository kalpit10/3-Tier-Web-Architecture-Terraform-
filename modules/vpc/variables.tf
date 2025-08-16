variable "vpc_cidr" {
  description = "CIDR block for the VPC (Main Network)"
  type        = string
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name      = string
    cidr      = string
    az        = string
    public_ip = bool
  }))
}

