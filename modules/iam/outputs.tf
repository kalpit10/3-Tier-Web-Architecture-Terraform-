output "iam_instance_profile_name" {
  value = aws_iam_instance_profile.cw_profile.name
}

######################################################
# 5. Output the role ARN for GitHub configuration
######################################################
# We’ll copy this ARN into GitHub repo settings so that
# GitHub Actions knows which role to assume.
output "gha_role_arn" {
  value = aws_iam_role.gha_tf.arn
}
