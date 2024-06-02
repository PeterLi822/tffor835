provider "aws" {
  region = "us-east-1" # Choose the appropriate AWS region
}

# Create ECR repositories
resource "aws_ecr_repository" "app_repository" {
  name = "my-app-repo"
}

resource "aws_ecr_repository" "mysql_repository" {
  name = "my-mysql-repo"
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get a specific public subnet in the default VPC
data "aws_subnet" "default" {
  filter {
    name   = "availabilityZone"
    values = ["us-east-1a"]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
  vpc_id = data.aws_vpc.default.id
}

# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create an EC2 instance
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.default.id

  tags = {
    Name = "MyAppInstance"
  }

  # Security group configuration
  security_groups = [aws_security_group.instance.id]

  # Commands to run at startup
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              EOF
}

# Create a security group
resource "aws_security_group" "instance" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
