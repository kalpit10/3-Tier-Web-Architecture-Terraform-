provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  vpc_name = "VPC-3-Tier"

  subnets = [
    {
      name      = "public-subnet-1"
      cidr      = "192.168.1.0/24"
      az        = "us-east-1a"
      public_ip = true
    },
    {
      name      = "public-subnet-2"
      cidr      = "192.168.2.0/24"
      az        = "us-east-1b"
      public_ip = true
    },
    {
      name      = "private-subnet-app-1"
      cidr      = "192.168.10.0/24"
      az        = "us-east-1a"
      public_ip = false
    },
    {
      name      = "private-subnet-app-2"
      cidr      = "192.168.11.0/24"
      az        = "us-east-1b"
      public_ip = false
    },
    {
      name      = "private-subnet-db-1"
      cidr      = "192.168.20.0/24"
      az        = "us-east-1a"
      public_ip = false
    },
    {
      name      = "private-subnet-db-2"
      cidr      = "192.168.21.0/24"
      az        = "us-east-1b"
      public_ip = false
    }
  ]
}
