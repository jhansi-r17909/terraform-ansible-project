terraform {

  backend "s3" {

    bucket         = "jhansi-s3-bucket-1203"
    key            = "terraform/terraform.tfstate"
    region         = "us-east-1"

    use_lockfile = true

    encrypt        = true

  }


}

