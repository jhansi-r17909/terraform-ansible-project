variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "c7i-flex.large"
}

variable "key_name" {
  description = "EC2 Key Pair"
}

variable "ami" {
  description = "Ubuntu AMI"
}