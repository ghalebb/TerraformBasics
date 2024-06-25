terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.55"
    }
  }
backend "s3" {
  bucket = "galeb-aws-bucket"
  key = "tfstate.json"
  region = "us-east-2"
}
  required_version = ">= 1.7.0"
}

provider "aws" {
  region  = var.region
  profile = "default"  # change in case you want to work with another AWS account profile
}

resource "aws_instance" "netflix_app" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.netflix_app_sg.name]
  key_name = aws_key_pair.netflix_app_key_pair.key_name
  user_data = file("./deploy.sh")
tags = {
  Name = "galeb-tf-instance${var.env}"
  Env = var.env
}
  depends_on = [aws_s3_bucket.netflix_app_bucket]
}

resource "aws_security_group" "netflix_app_sg" {
  name = "galeb-netflix-app-sg"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "netflix_app_key_pair" {
  key_name = "galebkey.pem"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDml320uguBXF6HamQv7IG+61WNyX4ZVB/zZux2Z+2zMwHzbtNg41ciS3KmbfoCKfUXljTiWT5AbsK/DSoZTnk890H/CP6UgqdvUuIaXT44DLu4Li2M4bhrx6MvKgJfj/zL5OsfNpi9c0TOSVXEianCG5y62PZSy4dKnUUunlmmZHBd2gyWNjGJJ3S5EC3KEPSM8CYCgLlFthCSle+XDJpcmXFRuLMW+ob3AcudwLinv2rgiQGmJqUbJOnfCZjA/lSFGTWcdvpaws1a91ntYjDOR/odclNYr8e8adNGllnFcMwVyTvP8ERBgmcYawlZqMBTx7MzKwhc/RyxuHcvXClh"
}

resource "aws_ebs_volume" "netflix_app_ebs" {
  availability_zone = "us-east-2a"
  size = 5
}
resource "aws_volume_attachment" "netflix_app_volume" {
  device_name = "/dev/sdh"
  volume_id = aws_ebs_volume.netflix_app_ebs.id
  instance_id   = aws_instance.netflix_app.id
}

resource "aws_s3_bucket" "netflix_app_bucket" {
  bucket = "galeb-netflix-app-bucket"
}


