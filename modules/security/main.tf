resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH from my IP"
  vpc_id      = var.vpc_id # Pass from root


  ingress {
    description = "SSH-Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols are allowed
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }

  # By default, when a resource needs to be replaced (e.g., due to an immutable attribute change), 
  # Terraform destroys the old resource before creating the new one.
  # Setting create_before_destroy = true ensures that the new resource is created successfully before the old one is destroyed, 
  # minimizing downtime for critical resources.
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP traffic from the internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbounds"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Allow traffic from ALB to EC2s"
  vpc_id      = var.vpc_id

  # Only traffic coming through the ALB can reach EC2s
  # Good for security, no direct access to EC2 from internet
  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Allow SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Allow MySQL access from App and Bastion"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from app instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description     = "MySQL from bastion host"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

// ----------------- KEY PAIRS -------------------------

// Generating Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "dev-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}
