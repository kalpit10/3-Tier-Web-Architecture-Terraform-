resource "aws_s3_bucket" "tfstate" {
  bucket        = var.bucket_name
  force_destroy = false
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Ownership controls (required for some regions)
resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

# Versioning
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}


# Default encryption (SSE-S3). 
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# DynamoDB lock table
resource "aws_dynamodb_table" "lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID" // DynamoDB uses this column to uniquely identify locks.

  attribute {
    name = "LockID"
    type = "S" // "S" means String type in DynamoDB. Lock IDs are text.
  }

  point_in_time_recovery {
    enabled = true // Enable PITR to protect against accidental deletes or overwrites.
  }
}
