data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_secret_arn
}

// Turns {"username":"","password":"xxxx","dbname":""} into a Terraform map, so we can call local.db_creds["username"].
locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}


resource "aws_db_subnet_group" "this" {
  name        = "finalproject-db-subnet-group"
  subnet_ids  = var.db_subnet_ids
  description = "Subnet group for RDS MYSQL DB"

  tags = {
    Name = "finalproject-db-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier        = "finalprojectdb"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.small"
  allocated_storage = 20

  username = local.db_creds["username"]
  password = local.db_creds["password"]
  db_name  = local.db_creds["dbname"]

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false

  tags = {
    Name = "finalproject-db"
  }
}

