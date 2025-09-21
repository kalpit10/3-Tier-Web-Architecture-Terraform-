terraform {
  backend "s3" {
    bucket         = "s3-terraform-state-bucket-kalpitswami"
    key            = "3-tier-architecture/terraform.tfstate" # path inside bucket (like a folder/file)
    region         = "us-east-1"
    dynamodb_table = "terraform-locks" # must match the table name
    encrypt        = true
  }
}
