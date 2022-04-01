# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.system_name}-${var.env_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.system_name}-${var.env_name}-igw"
  }
}

# Public Subnet関係
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.system_name}-${var.env_name}-public-rtb"
  }
}

resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.public-rtb.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"
  tags = {
    Name = "${var.system_name}-${var.env_name}-public-subnet1"
  }
}

resource "aws_route_table_association" "public-subnet-1-rtb-association" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-rtb.id
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"
  tags = {
    Name = "${var.system_name}-${var.env_name}-public-subnet2"
  }
}

resource "aws_route_table_association" "public-subnet-2-rtb-association" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-rtb.id
}


# Private Subnet関係
resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.system_name}-${var.env_name}-private-rtb"
  }
}

resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "${var.system_name}-${var.env_name}-private-subnet1"
  }
}

resource "aws_route_table_association" "private-subnet-1-rtb-association" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.private-rtb.id
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "${var.system_name}-${var.env_name}-private-subnet2"
  }
}

resource "aws_route_table_association" "privte-subnet-2-rtb-association" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.private-rtb.id
}