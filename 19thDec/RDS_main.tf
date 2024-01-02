terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.50.0"
    }
  }
}

# Define the AWS provider
provider "aws" {
  region = "us-east-1"  # Specify your desired AWS region
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

# Create two subnets in different availability zones
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Specify your desired availability zone
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"  # Specify your desired availability zone
}

# Create an RDS instance in one of the subnets
resource "aws_db_instance" "my_db_instance" {
  identifier            = "my-rds-instance"
  allocated_storage     = 20
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t2.micro"
  name                  = "mydatabase"
  username              = "admin"
  password              = "adminpassword"
  db_subnet_group_name  = aws_db_subnet_group.my_db_subnet_group.name

  vpc_security_group_ids = [aws_security_group.db_security_group.id]
}

# Create a DB subnet group for the RDS instance
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

# Create a security group for the RDS instance
resource "aws_security_group" "db_security_group" {
  name        = "db-security-group"
  description = "Allow inbound MySQL traffic"
  vpc_id      = aws_vpc.my_vpc.id 
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance
resource "aws_instance" "my_ec2_instance" {
  ami             = "ami-06aa3f7caf3a30282"  # Specify your desired AMI
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.subnet1.id
  key_name        = "hadiya-keypair"  # Specify your key pair name
    vpc_security_group_ids = [aws_security_group.db_security_group.id] 

  tags = {
    Name = "my-ec2-instance"
  }
}

# Create a VPC endpoint for RDS (AWS PrivateLink)
resource "aws_vpc_endpoint" "rds_endpoint" {
  vpc_id = aws_vpc.my_vpc.id

  service_name = "com.amazonaws.us-east-1.rds"  # Adjust the region accordingly

  security_group_ids = [aws_security_group.db_security_group.id]
 
 subnet_ids = [
    aws_subnet.subnet1.id,
    aws_subnet.subnet2.id,
  ]
  
}

# Output the RDS instance endpoint for reference
output "rds_instance_endpoint" {
  value = aws_db_instance.my_db_instance.endpoint
}
