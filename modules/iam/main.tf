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

/*
- An instance profile is a container for the IAM role.
- When launching an EC2 instance, we cannot attach a role directly
- We attach the instance profile, which wraps the role
*/
resource "aws_iam_instance_profile" "cw_profile" {
  name = "cw-agent-instance-profile"
  role = aws_iam_role.cloudwatch_agent_role.name
}

