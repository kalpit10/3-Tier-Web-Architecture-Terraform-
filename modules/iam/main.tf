// This role is now trusted by EC2, meaning any EC2 instance assigned to this role will act with this role’s permissions.
resource "aws_iam_role" "cloudwatch_agent_role" {
  name = "ec2-cloudwatch-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole", # allows assuming this role
        Principal = {
          Service = "ec2.amazonaws.com" # only EC2 instances can assume it
        }
      }
    ]
  })
}

// This policy defines what actions are allowed for the EC2 instance that assumes the role.
// There is a built-in policy named: CloudWatchAgentServerPolicy, but we will create our own to have better understanding of IAM
/*
- Push metrics (cloudwatch:PutMetricData)
- Push logs to new log groups (logs:*)
- Read volume info if needed for disk metrics
*/
resource "aws_iam_policy" "cloudwatch_agent_policy" {
  name        = "cloudwatch-agent-policy"
  description = "Policy for CloudWatch Agent access to logs and metrics"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  role       = aws_iam_role.cloudwatch_agent_role.name
  policy_arn = aws_iam_policy.cloudwatch_agent_policy.arn
}

# Allow EC2 instances to read only our DB secret
resource "aws_iam_policy" "secretsmanager_read" {
  name        = "secretsmanager-read-db-secret"
  description = "Policy for EC2 to read the DB credentials secret"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = var.db_secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secretsmanager_read" {
  role       = aws_iam_role.cloudwatch_agent_role.name // attaching to the same role as CloudWatch agent
  policy_arn = aws_iam_policy.secretsmanager_read.arn
}


/*
- An instance profile is a container for the IAM role.
- When launching an EC2 instance, we cannot attach a role directly
- We attach the instance profile, which wraps the role
*/
resource "aws_iam_instance_profile" "cw_profile" {
  name = "cw-agent-instance-profile"
  role = aws_iam_role.cloudwatch_agent_role.name
}

#-------------------------
# GitHub Actions Role
#-------------------------

# 1. GitHub OIDC provider
# This tells AWS: "Trust GitHub Actions tokens that come from token.actions.githubusercontent.com".
# It enables short-lived credentials instead of long-lived keys.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # GitHub tokens are always meant for sts.amazonaws.com (the AWS STS service)
  client_id_list = ["sts.amazonaws.com"]

  # This thumbprint is GitHub’s root CA cert fingerprint
  # (it rarely changes; AWS docs provide it).
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# 2. Define a trust policy for the GitHub role

# This policy says:
# - Only allow "sts:AssumeRoleWithWebIdentity" via OIDC provider.
# - Must come from our GitHub repo (kalpit10/3-Tier-Web-Architecture-Terraform).
data "aws_iam_policy_document" "gha_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    # Trust only the OIDC provider created above
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Condition 1: Audience must equal sts.amazonaws.com
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Condition 2: Subject must match our repo
    # Format: repo:<owner>/<repo>:<ref>
    # Example: * matches any branch/tag in the repo.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:kalpit10/3-Tier-Web-Architecture-Terraform-:*"
      ]
    }
  }
}

######################################################
# 3. Create the IAM Role for GitHub Actions
######################################################
# This is the role GitHub will assume when running workflows.
resource "aws_iam_role" "gha_tf" {
  name               = "gha-terraform-role"
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
}

######################################################
# 4. Attach permissions to the role
######################################################
# For now, give AdministratorAccess (easy for testing).
# Later, we will replace this with least-privilege policies.
resource "aws_iam_role_policy_attachment" "gha_admin" {
  role       = aws_iam_role.gha_tf.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


