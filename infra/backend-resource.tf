resource "aws_s3_bucket" "terraform_state" {

  bucket = "kubecoin-terraform-state-bucket-nidhi"

  tags = {
    Name = "terraform-state"
  }

}

# enable versioning 

resource "aws_s3_bucket_versioning" "versioning" {

  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }

}

#dynamodb-table

resource "aws_s3_bucket_versioning" "versioning" {

  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }

}