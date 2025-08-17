# Development Environment - 3-Tier Architecture

This repository contains the complete **Terraform configuration** for a modular, production-style **3-Tier AWS architecture**.

## Architecture Overview

A traditional 3-tier structure using **VPC**, **subnets**, **EC2**, **ALB**, **ASG**, and **RDS**, fully written in Terraform.

### 🌐 Web Tier (Public Subnets)

- **Application Load Balancer (ALB)** — Handles all incoming HTTP traffic
- **Public Subnets** — `192.168.1.0/24` (AZ A), `192.168.2.0/24` (AZ B)
- **Internet Gateway** — Allows public internet access
- **Security Group** — Allows port 80 (HTTP) traffic from the internet

### 🖥️ Application Tier (Private Subnets)

- **Auto Scaling Group (ASG)** — Maintains 2–6 EC2 instances
- **Launch Template** — With Amazon Linux 2023 and CloudWatch Agent
- **Private Subnets** — `192.168.10.0/24`, `192.168.11.0/24`
- **NAT Gateways** — 2 for outbound internet access
- **Security Group** — Allows HTTP only from ALB

### 🗄️ Database Tier (Private Subnets)

- **RDS MySQL** — Single-AZ for cost savings
- **DB Subnet Group** — `192.168.20.0/24`, `192.168.21.0/24`
- **Security Group** — Allows MySQL traffic only from EC2 instances

---

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

---

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **AWS Account** with necessary permissions

---

## Deployment Instructions

### 1. Initialize Terraform if using Cloud9 environment 

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

### 2. Connect via VS Code

```bash
aws configure
-- Enter AWS Access Key
-- Enter AWS Secret
```

### 3. Validate the Syntax
```bash
terraform validate
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Deploy the Infrastructure

```bash
terraform apply -auto-approve
```

### 6. Access Your Application

After deployment, Terraform will output the Application Load Balancer DNS name:

```
application_url = "http://dev-3tier-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com"
```

---

## Setting Up and Testing the PHP Application

### Pre-requisites
Before testing the form submission, you need to create the required database table.

### Step 1: Connect to Bastion Host
1. Navigate to **EC2 Console** → **Instances**
2. Select your **Bastion Host** instance
3. Click **Connect** → **EC2 Instance Connect**

### Step 2: Access Private EC2 Instance
From the Bastion Host, SSH into one of your private EC2 instances:
```bash
ssh -i your-key.pem ec2-user@<private-ec2-ip>
```

### Step 3: Install MySQL Client
Install MariaDB client to connect to the RDS MySQL database:
```bash
sudo yum update -y
sudo yum install -y mariadb105
```

### Step 4: Create Database Table
Connect to your RDS instance and create the required table:
```bash
mysql -h finalprojectdb.xxxxxxxxxxxxxxxx.us-east-1.rds.amazonaws.com -u <db_username> -p
```
Once connected, run these SQL commands:
```bash
-- Use the database
USE finalprojectdb;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Verify table creation
DESCRIBE users;

-- Exit MySQL
EXIT;
```

### Step 5: Test the Application
- Open your Application Load Balancer DNS name in a web browser
- You should see the PHP form with Instance ID displayed. Refresh the page to switch between instances.
- Fill in the form with a name and email
- Submit the form to test database connectivity

```bash
-- Connect again
mysql -h finalprojectdb.xxxxxxxxxxxxxxxx.us-east-1.rds.amazonaws.com -u <db_username> -p

use finalprojectdb;

-- Check submitted data
SELECT * FROM users;
```

---

## What Gets Created

### Networking (VPC Module)

- 1 VPC with DNS hostnames enabled
- 1 Internet Gateway
- 2 Public subnets across 2 AZs
- 4 Private subnets across 2 AZs
- 2 NAT Gateways with Elastic IPs
- Route tables and associations

### Security (Security Module)

- ALB SG: Allows HTTP from anywhere
- App SG: Allows HTTP only from ALB (Security Group Chaining)
- DB SG: Allows MySQL from App SG
- Bastion SG: Allows SSH via key pair

### Application (Application Module)

- Application Load Balancer
- Target Group with Health Checks
- Launch Template with Amazon Linux 2023, CloudWatch Agent, user-data.sh for PHP form setup
- Auto Scaling Group (2-6 instances)

### Database (Database Module)

- RDS MySQL instance
- DB Subnet Group

---

## Security Features

- **Network Isolation**: Multi-tier subnet architecture
- **Security Groups**: Least-privilege access rules. Security Group Chaining.
- **Encryption**: EBS volumes and RDS storage encrypted
- **IMDSv2**: Required on all EC2 instances

---

## Monitoring and Logging

- **CloudWatch Logs (Log Groups)**:  /ec2/log/access || /ec2/log/error
- **CloudWatch Agent**: CPU, Memory, Disk metrics
- **CloudWatch Dashboard**: CPU and Memory% Monitoring Per Instance
- **Health Checks**: ALB health checks for application instances
- **Auto Scaling**: Based on instance cpu load.
 
---

## AWS Cost Optimization Overview

This development environment is optimized for cost:

### Cost Optimization Overview (Per Hour)

| AWS Service           | Resource Type              | Quantity          | Est. Hr. Cost (USD) | Notes               |
|-----------------------|----------------------------|-------------------|---------------------|---------------------|
| VPC & Subnets         | VPC, Subnets, RTs          | 1 VPC + 6 Subnets | $0.00               | Free                |
| Internet Gateway      | -                          | 1                 | $0.00               | Free                |
| NAT Gateway           | NAT + Data                 | 2                 | ~$0.045/hr each     | $0.09/hr total      |
| EC2 Instances         | t2.micro                   | 2-6               | ~$0.0116/hr each    | Free Tier may apply |
| EBS Volumes           | 8GB gp3                    | 2-6               | ~$0.0011/hr per 8GB | Free Tier may apply |
| ALB (Load Balancer)   | Application Load Balancer  | 1                 | ~$0.0225/hr         | Plus ~$0.008 per GB |
| RDS MySQL             | db.t2.micro                | 1                 | ~$0.017/hr          | Single-AZ           |
| RDS Storage           | 20GB gp2/gp3               | 1                 | ~$0.0025/hr         | $0.08/GB-month      |
| CloudWatch Logs       | Log ingestion              | Variable          | ~$0.005-0.01/hr     | Based on usage      |
| CloudWatch Agent      | Basic EC2 metrics          | 2-6 EC2s          | ~$0.00/hr           | Free (Basic)        |
| CloudWatch Dashboards | 1 Dashboard                | 1                 | ~$0.0083/hr         | $3/month flat rate  |

⚠️ **Note:** Data transfer, EIP association, and scaling events can increase charges slightly.

### Total Estimated Hourly Cost

| Tier       | Description                      | Approx. Cost Range (/hr)  |
|------------|----------------------------------|---------------------------|
| Networking | NAT, IGW, VPC, Subnets           | ~$0.09                    |
| Compute    | EC2 + ALB + EBS                  | ~$0.02 - $0.12            |
| Database   | RDS + Storage                    | ~$0.02                    |
| Monitoring | CloudWatch + Logs + Dashboard    | ~$0.005 - $0.02           |

💡 **Estimated Total: ~$0.13 to $0.28/hour** depending on active instances and log volume.

**Estimated Monthly Cost**: ~$50-80 USD (varies by usage)

---

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

---

## Troubleshooting

### Troubleshooting Guide

| Issue                        | Solution                                                          |
|------------------------------|-------------------------------------------------------------------|
| App Not Loading in Browser   | Check ALB Target Group health status                              |
| CloudWatch Agent Not Running | Ensure metadata token (IMDSv2) is fetched correctly               |
| SSH Not Working              | Ensure `.pem` key has `chmod 600` and correct private IP used     |
| No CPU Metrics Visible       | Use `stress` tool to simulate load                                |


---

## Useful Commands

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

---

## Learning Objectives Achieved

- ✅ **Terraform Basics**: Variables, outputs, modules, data sources
- ✅ **AWS Networking**: VPC, subnets, routing, NAT gateways
- ✅ **Security**: Security groups, least privilege access
- ✅ **High Availability**: Multi-AZ deployment, auto scaling
- ✅ **CloudWatch Observability**: CloudWatch agent, custom metrics, dashboards
- ✅ **Database Management**: RDS, parameter groups, secrets management
- ✅ **Infrastructure as Code**: Modular, reusable Terraform code
- ✅ **Debugging & Troubleshooting**: Solved real IAM, metadata, health check, and CloudWatch agent issues

This development environment provides a solid foundation for learning AWS and Terraform while following best practices for a production-ready architecture.
