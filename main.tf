terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My-vpc"
  }
}

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "intgw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "internet-gateway"
  }
}

resource "aws_route_table" "routable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.intgw.id
  }

  tags = {
    Name = "route-table"
  }
}

resource "aws_route_table_association" "assroutetable" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.routable.id
}

resource "aws_eip" "eip" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "ntgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "gw NAT"
  }

}

resource "aws_route_table" "priroutable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.intgw.id
  }

  tags = {
    Name = "route-table"
  }
}

resource "aws_route_table_association" "priassroutetable" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.priroutable.id
}

resource "aws_security_group" "secgroup" {
  name        = "My-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main-sg"
  }
}

resource "aws_instance" "instance1" {
  ami           = "ami-0ad21ae1d0696ad58"  # Replace with a valid Ubuntu AMI ID for your region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.pubsub.id
  vpc_security_group_ids = [aws_security_group.secgroup.id]
  key_name = "laptop"
  associate_public_ip_address = true

  tags = {
    Name = "instance1"
  }
}

resource "aws_instance" "instance2" {
  ami           = "ami-0ad21ae1d0696ad58"  # Replace with a valid Ubuntu AMI ID for your region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.prisub.id
  vpc_security_group_ids = [aws_security_group.secgroup.id]
  key_name = "laptop"
  associate_public_ip_address = true

  tags = {
    Name = "instance2"
  }
}