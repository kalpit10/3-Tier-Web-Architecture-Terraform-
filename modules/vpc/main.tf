# -------------------------VPC---------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # Enables internal DNS (for EC2 hostname resolution)
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# -------------------------- SUBNETS ---------------------------------

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

# ----------------------------EIP------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.vpc_name}-nat-eip"
  }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"

  tags = {
    Name = "${var.vpc_name}-nat-eip-b"
  }
}

# ----------------------------IGW -----------------------------------

resource "aws_internet_gateway" "final_igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}


# --------------------------NAT-GW-------------------------------------

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.all["public-subnet-1"].id

  tags = {
    Name = "${var.vpc_name}-nat-AZ1"
  }
}


resource "aws_nat_gateway" "b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.all["public-subnet-2"].id

  tags = {
    Name = "${var.vpc_name}-nat-AZ2"
  }
}

# ------------------------- PUBLIC ROUTE TABLE ---------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "public-rt"
  }
}

# Attaching IGW to public-rt (Edit Routes inside console)
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.final_igw.id
}

# Associate public subnets to public-rt
resource "aws_route_table_association" "public" {
  # Only loop through subnets marked as public
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if subnet.public_ip == true
  }

  # Match the subnet name to the correct aws_subnet ID
  subnet_id      = aws_subnet.all[each.key].id
  route_table_id = aws_route_table.public.id
}

# ----------------------------- PRIVATE ROUTE TABLE-1 -------------------------------

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "private-rt-1"
  }
}


resource "aws_route" "pvt-internet-access_1" {
  route_table_id         = aws_route_table.private_1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "pvt-internet-access_1" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if subnet.public_ip == false && subnet.cidr == "192.168.10.0/24"
  }

  subnet_id      = aws_subnet.all[each.key].id
  route_table_id = aws_route_table.private_1.id
}

# ----------------------------- PRIVATE ROUTE TABLE-2 -------------------------------

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "private-rt-2"
  }
}

resource "aws_route" "pvt-internet-access_2" {
  route_table_id         = aws_route_table.private_2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.b.id
}

resource "aws_route_table_association" "pvt-internet-access_2" {
  for_each = { for subnet in var.subnets : subnet.name => subnet
    if subnet.public_ip == false && subnet.cidr == "192.168.11.0/24"
  }

  subnet_id      = aws_subnet.all[each.key].id
  route_table_id = aws_route_table.private_2.id
}


# ------------------------- DB RT ---------------------------------

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "private-db-rt"
  }
}

resource "aws_route_table_association" "private_db" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if subnet.public_ip == false && contains(["192.168.20.0/24", "192.168.21.0/24"], subnet.cidr)
  }

  subnet_id      = aws_subnet.all[each.key].id
  route_table_id = aws_route_table.private_db.id
}

