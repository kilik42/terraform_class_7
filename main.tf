terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


provider "aws"{
  region = var.region
}

variable vpc_cidr_block{}
variable subnet_cidr_block_1{}
variable subnet_cidr_block_2{}
variable avail_zone{}
variable env_prefix{}
variable region{}
variable my_ip{}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block_1
  availability_zone = var.avail_zone

  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_subnet" "myapp-subnet-2" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block_2
  availability_zone = var.avail_zone

  tags = {
    Name = "${var.env_prefix}-subnet-2"
  }
}

# internet gateway
# route to connect to the internet 
# an IGW is required for public subnets to access the internet
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}


##################route tables#######################
# route table for internal traffic 
resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-private-route-table"
  }
}


# route table association
resource "aws_route_table_association" "myapp-route-table-assoc-private-1" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}


##################public route tables#######################
# route table for connecting to the internet
resource "aws_route_table" "myapp-public-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name = "${var.env_prefix}-public-route-table"
  }
}


# route table association
resource "aws_route_table_association" "myapp-route-table-assoc-public-1" {
  subnet_id      = aws_subnet.myapp-subnet-2.id
  route_table_id = aws_route_table.myapp-public-route-table.id
}

resource "aws_security_group" "myapp-sg" {
  name        = "${var.env_prefix}-sg"
  description = "Security group for my app"
  vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] 
    }

    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    # protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]     
  }
}


output "vpc_id" {
  value = aws_vpc.myapp-vpc.id
}