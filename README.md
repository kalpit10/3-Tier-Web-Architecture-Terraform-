# Development Environment - 3-Tier Architecture

This repository contains the complete **Terraform configuration** for a modular, production-style **3-Tier AWS architecture**.

## Architecture Overview

A traditional 3-tier structure on AWS using **VPC**, **subnets**, **ALB**, **ASG/EC2**, and **RDS**, fully managed with Terraform.

### 🌐 Web Tier (Public Subnets)

- **Application Load Balancer (ALB)**
  - Listens on HTTP :80
  - **Health check** path: `/healthcheck.php` (lightweight DB reachability)
- **Public subnets**: `192.168.1.0/24` (us-east-1a), `192.168.2.0/24` (us-east-1b)
- **Internet Gateway** for inbound/outbound internet
- **Security Group (ALB)**: allow TCP/80 from `0.0.0.0/0`
- **Bastion host** (for admin SSH) in a public subnet, SG restricted to my IP

### 🖥️ Application Tier (Private Subnets)

- **Auto Scaling Group (ASG)** across two private subnets: `192.168.10.0/24`, `192.168.11.0/24`
- **Launch Template**
  - Amazon Linux 2023
  - **User data** bootstraps Apache/PHP, installs CloudWatch Agent, and **pulls DB creds from AWS Secrets Manager** to generate `db.php`
  - Uses **IMDSv2** in scripts
- **IAM instance profile**
  - Grants least-necessary access: `secretsmanager:GetSecretValue` and CloudWatch logs/metrics
- **NAT Gateways (2)** for outbound internet from private subnets
- **Security Group (App)**: allow TCP/80 **only** from ALB SG

### 🗄️ Database Tier (Private Subnets)

- **Amazon RDS for MySQL** (Single-AZ, cost-optimized)
- **DB subnets**: `192.168.20.0/24`, `192.168.21.0/24`
- **Security Group (DB)**: allow TCP/3306 **only** from App SG
- **Credentials**: app tier reads username/password/dbname **from AWS Secrets Manager** at boot; no secrets hardcoded in code

### 🛠️ Platform & Ops Components

- **Monitoring**: CloudWatch Agent on EC2; ALB health checks decoupled from app logic
- **Access control**: IAM roles and scoped policies for EC2 + CI/CD
- **(IaC) Remote state & locking**: S3 (versioned, SSE) + DynamoDB table for state locking
- **CI/CD**: GitHub Actions with **OIDC** to assume an AWS role (no long-lived keys)
  - PRs: `fmt` / `validate` / `plan`
  - `main`: manual approval gate → `apply`

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

After the infrastructure is applied, a **private key** will be generated and stored under the `modules/security` folder.

1. **SSH into the Bastion Host** (public subnet):

   ```bash
   ssh -i your-key.pem ec2-user@<bastion-public-ip>
   ```

2. **On the Bastion Host**, create a new file for the private key:

   ```bash
   nano <key_name>.pem
   ```

   Paste the contents of the private key generated from the `modules/security` folder into this file.

3. **Set the correct permissions**:

   ```bash
   chmod 400 <key_name>.pem
   ```

4. **Now use this key to SSH into one of the private EC2 instances**:
   ```bash
   ssh -i <key_name>.pem ec2-user@<private-ec2-ip>
   ```

### Step 3: Access MySQL

Connect to your RDS instance:

```bash
mysql -h finalprojectdb.xxxxxxxxxxxxxxxx.us-east-1.rds.amazonaws.com -u <db_username> -p
```

Once connected, run these SQL commands:

```bash
-- Use the database
USE finalprojectdb;

-- Verify table creation
DESCRIBE users;

-- Exit MySQL
EXIT;
```

### Step 4: Test the Application

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
- **Key Management**: Terraform generates and stores a private key under `modules/security`

### Application (Application Module)

- Application Load Balancer
- Target Group with Health Checks (now pointed to `/healthcheck.php` for reliability)
- Launch Template with Amazon Linux 2023, CloudWatch Agent, user-data.sh for PHP form setup
- Auto Scaling Group (2-6 instances)
- **Secrets Manager Integration**: Application retrieves DB credentials securely from AWS Secrets Manager
- **Improved Health Checks**: Lightweight `healthcheck.php` deployed to instances for reliable ALB health monitoring

### Database (Database Module)

- RDS MySQL instance
- DB Subnet Group
- **Dynamic Credentials**: Managed via AWS Secrets Manager
- **Secure Access**: Only App SG can connect to DB SG

---

## Security Features

- **Network Isolation**: Multi-tier subnet architecture
- **Security Groups**: Least-privilege access rules with Security Group Chaining
- **Encryption**: EBS volumes and RDS storage encrypted
- **IMDSv2**: Required on all EC2 instances
- **Secrets Management**: DB credentials stored securely in AWS Secrets Manager instead of hardcoded in user-data
- **IAM Roles**: Instance profiles allow EC2 to fetch secrets and send metrics/logs

---

## Monitoring and Logging

- **CloudWatch Logs (Log Groups)**: /ec2/log/access || /ec2/log/error
- **CloudWatch Agent**: CPU, Memory, Disk metrics
- **CloudWatch Dashboard**: CPU and Memory% Monitoring Per Instance
- **Health Checks**: ALB health checks now use `/healthcheck.php`
- **Auto Scaling**: Based on instance CPU load
- **Improved Debugging**: Added testdb.php and healthcheck.php for validation and troubleshooting

---

## Infrastructure Management

- **Terraform Remote State**: Managed with S3 backend and DynamoDB table for state locking
- **CI/CD with GitHub Actions**:
  - OIDC integration with AWS (no long-lived keys)
  - `terraform fmt`, `validate`, and `plan` on push to main as well as pull requests
  - `terraform apply` gated by manual approval in `dev` environment
- **Version Control**: All IaC stored in GitHub repository

---

## AWS Cost Optimization Overview

This development stack stays small but not free. Figures below reflect current public pricing for **US-East-1**.
Always confirm with the AWS Pricing Calculator for exact workloads.

### Cost Breakdown (Per Hour)

| AWS Service                   | Resource Type             |          Quantity |                                Est. Hr. Cost (USD) | Notes                                                                |
| ----------------------------- | ------------------------- | ----------------: | -------------------------------------------------: | -------------------------------------------------------------------- |
| VPC & Subnets                 | VPC, Subnets, RTs         | 1 VPC + 6 Subnets |                                              $0.00 | Core VPC constructs are free.                                        |
| Internet Gateway              | —                         |                 1 |                                              $0.00 | IGW has no hourly fee.                                               |
| **NAT Gateway**               | NAT + Data                |             **2** |                  **$0.045/hr each** → **$0.09/hr** | Plus **$0.045/GB** processed through NAT.                            |
| **EC2 Instances**             | **t2.micro** (Linux)      |           **2–6** |       **$0.0116/hr each** → **$0.0232–$0.0696/hr** | On-demand price in us-east-1.                                        |
| **EBS Volumes**               | **gp3** 8 GB per instance |               2–6 | **~$0.00089/hr per 8 GB** → **$0.0018–$0.0053/hr** | gp3 is **$0.08/GB-mo**.                                              |
| **Application Load Balancer** | ALB                       |                 1 |                 **$0.0225/hr + $0.008 per LCU-hr** | Light dev traffic often <1 LCU.                                      |
| **RDS MySQL**                 | **db.t3.micro**           |                 1 |                              **~$0.017–$0.018/hr** | On-demand us-east-1.                                                 |
| **RDS Storage**               | gp3 **20 GB**             |                 1 |                                    **~$0.0022/hr** | $0.08/GB-mo → $1.60/mo.                                              |
| CloudWatch Logs               | Log ingestion             |          Variable |                                           Variable | After free tier, ingestion commonly **$0.50/GB** range; usage-based. |
| **CloudWatch Dashboard**      | 1 dashboard               |                 1 |                                    **~$0.0042/hr** | $3 per dashboard per month.                                          |
| **Secrets Manager**           | 1 secret                  |                 1 |                                   **~$0.00056/hr** | **$0.40/secret-mo** + **$0.05/10k API calls**.                       |
| S3 Backend                    | Standard storage          |            Few MB |                                             ~$0.00 | Pennies per month for state file.                                    |
| DynamoDB Locking              | Pay-per-request           |       Light usage |                                             ~$0.00 | Lock table with on-demand reads/writes for Terraform.                |

### Estimated Total Hourly Cost

| Tier       | Description            |                             Approx. Cost Range (/hr) |
| ---------- | ---------------------- | ---------------------------------------------------: |
| Networking | NAT, IGW, VPC          |                                           **~$0.09** |
| Compute    | EC2 + EBS + ALB base   | **~$0.05–$0.10** (depends on EC2 count and ALB LCUs) |
| Database   | RDS + Storage          |                                   **~$0.019–$0.020** |
| Monitoring | CloudWatch + Dashboard |                 **~$0.004–$0.01** (ingestion varies) |
| Secrets    | Secrets Manager        |                                         **~$0.0006** |

**Estimated Total:** **~$0.16–$0.22 per hour** for typical dev usage, excluding variable data transfer and log ingestion. That’s roughly **$115–$160/month** if left running 24×7. Your largest steady cost remains the **two NAT Gateways**.

> Notes  
> • **ALB LCUs** add cost with throughput, new connections, active connections, or rule evaluations; base hourly is fixed.  
> • **gp3 vs gp2**: gp3 is cheaper at **$0.08/GB-mo** and recommended.  
> • **Secrets Manager** has a small fixed fee; Parameter Store standard tier would be free but lacks native rotation.

#### Where to Save Fast

- Replace **2 NAT Gateways** with **1** during dev or try **NAT instance** for labs. Biggest dollar lever.
- Keep **ALB** only when testing.
- Stop **RDS** and **EC2** when idle or script full teardown.

---

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

---

## Troubleshooting

### Troubleshooting Guide

| Issue                            | Possible Cause                                 | Solution                                                                                                              |
| -------------------------------- | ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **App not loading in browser**   | ALB Target Group shows **Unhealthy** instances | • Verify ALB health check path (use `/healthcheck.php`)<br>• Check Apache/PHP error logs (`/var/log/httpd/error_log`) |
| **CloudWatch Agent not running** | IMDSv2 token or config not retrieved properly  | • Confirm script fetches IMDSv2 token correctly<br>• Run `sudo systemctl status amazon-cloudwatch-agent`              |
| **SSH not working**              | Incorrect key permissions or IP mismatch       | • Ensure `.pem` file has `chmod 400`<br>• Use Bastion host with correct private IP of target instance                 |
| **No CPU metrics visible**       | Agent running but no workload generated        | • Install `stress` tool (`sudo yum install stress -y`)<br>• Run `stress --cpu 2 --timeout 60` to generate load        |
| **500 Internal Server Error**    | Missing DB table or PHP extension              | • Ensure `users` table exists in RDS<br>• Verify PHP `mysqli` extension is installed                                  |
| **Secrets not loading**          | Placeholder values left in `db.php`            | • Check `/var/www/html/db.php` contains actual DB creds<br>• Verify `user-data.sh` fetches from Secrets Manager       |
| **Terraform apply fails**        | Remote state or secret already exists          | • Run `terraform state rm <resource>` to unlink<br>• Or use `terraform import` to reattach existing resource          |

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

- ✅ **Terraform Proficiency**: Learned variables, outputs, modules, data sources, and implemented remote backend with S3 + DynamoDB for secure state management.
- ✅ **AWS Networking**: Designed a VPC with public/private subnets, routing, Internet/NAT Gateways, and Bastion Host for secure access.
- ✅ **Security & Identity**: Applied least-privilege security groups, IAM instance roles for Secrets Manager and CloudWatch, and OIDC-based IAM role for GitHub Actions.
- ✅ **High Availability & Scalability**: Configured ALB + Auto Scaling Group across multiple AZs, using launch templates with dynamic user data.
- ✅ **Observability & Monitoring**: Deployed CloudWatch Agent for EC2 metrics, created dashboards, and integrated custom health checks (`healthcheck.php`) for ALB.
- ✅ **Database Management**: Provisioned RDS MySQL with private subnets, subnet groups, Secrets Manager integration, and verified secure app connectivity.
- ✅ **Infrastructure as Code (IaC)**: Built fully modular Terraform codebase with reusable modules for VPC, ALB, ASG, RDS, and Security.
- ✅ **CI/CD Automation**: Implemented GitHub Actions pipeline with Terraform plan, manual approval, and apply using OIDC for secure AWS access.
- ✅ **Debugging & Troubleshooting**: Resolved real-world issues (IMDSv2, CloudWatch agent config, IAM permission errors, ALB health check 500s, PHP app/database integration).

📌 This environment not only strengthens AWS + Terraform fundamentals but also simulates **production-grade workflows** with security, automation, and troubleshooting practices.
