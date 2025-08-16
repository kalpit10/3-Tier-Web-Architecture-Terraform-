
# Development Environment - 3-Tier Architecture

This directory contains the Terraform configuration for the development environment of our 3-tier AWS architecture.

## Architecture Overview

This development environment creates a complete 3-tier architecture with the following components:

### 🌐 Web Tier (Public Subnets)
- **Application Load Balancer (ALB)** - Distributes incoming traffic
- **Public Subnets** - 192.168.1.0/24, 192.168.2.0/24
- **Internet Gateway** - Provides internet access
- **Security Group** - Allows HTTP from internet

### 🖥️ Application Tier (Private Subnets)
- **Auto Scaling Group** - Manages EC2 instances (2-6 instances)
- **Launch Template** - Defines instance configuration
- **Private App Subnets** - 192.168.10.0/24, 192.168.11.0/24
- **NAT Gateways** - Provides outbound internet access
- **Security Group** - Allows traffic from ALB only

### 🗄️ Database Tier (Private Subnets)
- **RDS MySQL Instance** - Managed database service
- **DB Subnet Group** - Spans multiple AZs (us-east-1a, us-east-1b)
- **Private DB Subnets** - 192.168.20.0/24, 192.168.21.0/24
- **Security Group** - Allows MySQL/Aurora traffic from app tier only
- **Secrets Manager** - Stores database credentials securely

## Development Environment Specifications

### Cost-Optimized Configuration
- **EC2 Instances**: t2.micro (2-6 instances)
- **RDS Instance**: db.t2.micro, single-AZ
- **Storage**: GP3 for cost-effective performance

### Network Configuration
- **VPC CIDR**: 192.168.0.0/16
- **Availability Zones**: 2 AZs for high availability(us-east-1a/1b)
- **Subnets**: 6 subnets total (2 public, 4 private)
- **NAT Gateways**: 2 for redundancy

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **AWS Account** with necessary permissions

## Deployment Instructions

### 1. Initialize Terraform
```bash
cd ~
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
ssh-keygen -t rsa -b 4096 -C "abc@email.com"
cat ~/.ssh/id_rsa.pub
git clone <SSH_ORIGIN_OF_REPO>
terraform init
```

### 2. Review the Plan
```bash
terraform plan
```

### 3. Deploy the Infrastructure
```bash
terraform apply
```

### 4. Access Your Application
After deployment, Terraform will output the Application Load Balancer DNS name:
```
application_url = "http://dev-3tier-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com"
```

## What Gets Created

### Networking (VPC Module)
- 1 VPC with DNS hostnames enabled
- 1 Internet Gateway
- 2 Public subnets across 2 AZs
- 4 Private subnets across 2 AZs
- 2 NAT Gateways with Elastic IPs
- Route tables and associations

### Security (Security Module)
- ALB Security Group (HTTP from internet)
- App Security Group (HTTP from ALB only)
- Database Security Group (MySQL from app servers only)
- Bastion Security Group (SSH access)

### Application (Application Module)
- Application Load Balancer
- Target Group with health checks
- Launch Template with Amazon Linux 2023
- Auto Scaling Group (2-6 instances)
- Auto Scaling Policies

### Database (Database Module)
- RDS MySQL instance
- DB Subnet Group

## Security Features

- **Network Isolation**: Multi-tier subnet architecture
- **Security Groups**: Least-privilege access rules. Security Group Chaining. 
- **Encryption**: EBS volumes and RDS storage encrypted
- **Secrets Management**: Database credentials in AWS Secrets Manager
- **IMDSv2**: Required on all EC2 instances

## Monitoring and Logging

- **CloudWatch Logs**: RDS error, general, and slow query logs
- **Health Checks**: ALB health checks for application instances
- **Auto Scaling**: Based on instance health

## Cost Considerations

This development environment is optimized for cost:
- Single-AZ RDS (no Multi-AZ)
- Minimal backup retention (1 day)
- Small instance types (t2.micro)
- No enhanced monitoring
- No Performance Insights

**Estimated Monthly Cost**: ~$50-80 USD (varies by usage)

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Insufficient Permissions**: Ensure your AWS credentials have the necessary IAM permissions
2. **Resource Limits**: Check AWS service limits in your region
3. **Subnet Conflicts**: Ensure CIDR blocks don't conflict with existing VPCs

### Useful Commands

```bash
# Check current state
terraform show

# List all resources
terraform state list

# Get specific resource details
terraform state show module.vpc.aws_vpc.main
terraform state list | grep resource_name/output_name

# Refresh state
terraform refresh
```

## Learning Objectives Achieved

✅ **Terraform Basics**: Variables, outputs, modules, data sources
✅ **AWS Networking**: VPC, subnets, routing, NAT gateways
✅ **Security**: Security groups, least privilege access
✅ **High Availability**: Multi-AZ deployment, auto scaling
✅ **Database Management**: RDS, parameter groups, secrets management
✅ **Infrastructure as Code**: Modular, reusable Terraform code

This development environment provides a solid foundation for learning AWS and Terraform while following best practices for a production-ready architecture.

**THIS PROJECT WAS MADE UNDER AWS ACADEMY VOCAREUM LAB PERMISSIONS. ENTIRE INFRASTRUCTURE WAS DEVELOPED USING CLOUD9 ENVIRONMENT. **