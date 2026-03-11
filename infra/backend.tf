terraform {

  backend "s3" {

    bucket         = "kubecoin-terraform-state-bucket-nidhi"
    key            = "minikube/terraform.tfstate"
    region         = "us-east-1"

    dynamodb_table = "terraform-lock-table"

    encrypt        = true

  }

}