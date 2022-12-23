# Specify AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.6"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "aws_ami" "ami-amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

}


data "aws_ami" "ami-ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

}


# Get VPC id of default VPC
data "aws_vpc" "default" {
  default = true
}

# Retrieve default tags
module "default_tags" {
  source = "../modules/global_vars"
}

# Provision SSH key pair for Linux VMs
resource "aws_key_pair" "linux_key" {
  key_name   = "linux_key"
  public_key = file(var.path_to_linux_key)
}

# Security Groups that allows SSH and HTTP access
module "linux_sg" {
  source     = "cloudposse/security-group/aws"
  attributes = ["primary"]

  # Allow unlimited egress
  allow_all_egress = true

  rules = [
    {
      key         = "ssh"
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = null
      description = "Allow SSH from anywhere"
    },
    {
      key         = "HTTP"
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = null
      description = "Allow HTTP from anywhere"
    }
  ]

  vpc_id = data.aws_vpc.default.id
}

# Create Amazon Linux EC2 instances in a default VPC
resource "aws_instance" "linux_vm" {
  count                  = var.num_linux_vms
  ami                    = data.aws_ami.ami-ubuntu.id
  key_name               = aws_key_pair.linux_key.key_name
  instance_type          = var.linux_instance_type
  vpc_security_group_ids = [module.linux_sg.id]
  user_data              = file("${path.module}/install_httpd.sh")
  tags = merge({
    Name = "UbuntuServer-${count.index}"
    },
    module.default_tags.default_tags
  )
}





