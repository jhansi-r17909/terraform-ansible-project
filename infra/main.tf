provider "aws" {
  region = var.region
}

# vpc and subents

resource "aws_vpc" "minikube_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "minikube-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.minikube_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "minikube-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.minikube_vpc.id

  tags = {
    Name = "minikube-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.minikube_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# security groups

resource "aws_security_group" "minikube_sg" {
  name   = "minikube-sg"
  vpc_id = aws_vpc.minikube_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "minikube-sg"
  }
}

# ec2 instances

resource "aws_instance" "minikube_server" {

  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = var.key_name

  vpc_security_group_ids = [
    aws_security_group.minikube_sg.id
  ]

  associate_public_ip_address = true

  tags = {
    Name = "minikube-server"
    Role = "control"
  }
}