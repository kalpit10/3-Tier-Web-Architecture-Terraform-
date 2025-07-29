resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # Enables internal DNS (for EC2 hostname resolution)
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "Final-Project-IGW" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}


resource "aws_subnet" "all" {
  // We are passing list of objects as input here
  // But, for_each requires a map for key and values..
  // In words: Take each subnet object inside the list var.subnets
  # Use its name as the key,
  # and the whole subnet object as the value.
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public_ip

  tags = {
    Name = each.value.name
  }
}