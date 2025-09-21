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

module "security" {
  source     = "./modules/security"
  vpc_id     = module.vpc.vpc_id
  my_ip_cidr = "0.0.0.0/0" # curl ifconfig.me
}


module "bastion" {
  source        = "./modules/bastion"
  ami_id        = "ami-0c101f26f147fa7fd" # Amazon Linux 2023 in us-east-1
  instance_type = "t2.micro"
  key_name      = module.security.key_name
  subnet_id     = module.vpc.subnet_ids["public-subnet-1"]
  bastion_sg_id = module.security.bastion_sg_id
}

module "alb" {
  source    = "./modules/alb"
  vpc_id    = module.vpc.vpc_id
  alb_sg_id = module.security.alb_sg_id
  public_subnet_ids = [
    module.vpc.subnet_ids["public-subnet-1"],
    module.vpc.subnet_ids["public-subnet-2"]
  ]
}

module "iam" {
  source        = "./modules/iam"
  db_secret_arn = aws_secretsmanager_secret.db_credentials.arn
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = var.db_secret_name
  description = "RDS credentials for the app tier"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = var.db_name
  })
}


module "rds" {
  source        = "./modules/rds"
  db_secret_arn = aws_secretsmanager_secret.db_credentials.arn

  db_subnet_ids = [
    module.vpc.subnet_ids["private-subnet-db-1"],
    module.vpc.subnet_ids["private-subnet-db-2"]
  ]
  db_sg_id = module.security.db_sg_id
}


# path.module just tells Terraform,
# “Start from this folder where my current .tf file is, and go find the JSON file from here.”
data "template_file" "cw_config" {
  template = file("${path.module}/cloudwatch-config/cloudwatch-agent-config.json")
}


module "asg" {
  source        = "./modules/asg"
  ami_id        = "ami-0c101f26f147fa7fd"
  instance_type = "t2.micro"
  key_name      = module.security.key_name
  app_sg_id     = module.security.app_sg_id
  private_subnet_ids = [
    module.vpc.subnet_ids["private-subnet-app-1"],
    module.vpc.subnet_ids["private-subnet-app-2"]
  ]
  target_group_arns = [module.alb.target_group_arn]
  // "Hey ASG module! Here’s the JSON config for CloudWatch agent. Please use it."
  cloudwatch_agent_config   = data.template_file.cw_config.rendered
  iam_instance_profile_name = module.iam.iam_instance_profile_name
  DB_HOST                   = module.rds.rds_endpoint
}



# data "aws_autoscaling_group" "app_asg" {
#   name = module.asg.asg_name
# }

// This returns all EC2 instances that have the tag Role = App
data "aws_instances" "app_ec2" {
  filter {
    name   = "tag:Role"
    values = ["App"]
  }
}

module "dashboard" {
  source         = "./modules/cloudwatch_dashboard"
  dashboard_name = "EC2-Dashboard-Metrics"
  aws_region     = "us-east-1"
  widgets        = local.ec2_dashboard_widgets
}


