# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name}-vpc"
    project = var.project_name
  }
}

# Subnets
resource "aws_subnet" "subnets" {
  for_each = var.subnet_cidrs

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = var.availability_zones[each.key]

  tags = {
    Name    = "${var.project_name}-${replace(each.key, "_", "-")}"  # reason: avoid underscores in AWS subnet names
    project = var.project_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "igw-${var.project_name}"
    project = var.project_name
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "eip_nat" {
  domain = "vpc"

  tags = {
    Name    = "eip-${var.project_name}"
    project = var.project_name
  }
}

# NAT Gateway (placed in subnet_1 - public subnet)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.eip_nat.id
  subnet_id     = aws_subnet.subnets["subnet_1"].id

  tags = {
    Name    = "nat-gway-${var.project_name}"
    project = var.project_name
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table 1 - Public (with IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "rt-${var.project_name}-public"
    project = var.project_name
  }
}

# Route Table 2 - Private (with NAT GW)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name    = "rt-${var.project_name}-private"
    project = var.project_name
  }
}

# Route Table Associations - Public (subnet_1 & subnet_3)
resource "aws_route_table_association" "public" {
  for_each = {
    subnet_1 = aws_subnet.subnets["subnet_1"].id
    subnet_3 = aws_subnet.subnets["subnet_3"].id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private (subnet_2 & subnet_4)
resource "aws_route_table_association" "private" {
  for_each = {
    subnet_2 = aws_subnet.subnets["subnet_2"].id
    subnet_4 = aws_subnet.subnets["subnet_4"].id
  }

  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}

# Security Group
resource "aws_security_group" "main" {
  name        = "${var.project_name}-sg-main"
  description = "Main security group for ${var.project_name}"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  # Allow SSH access from anywhere (for testing)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access"
  }

  # Allow MySQL/Aurora traffic within the same security group
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    self        = true
    description = "Allow RDS connection from within SG"
  }

  # Allow all TCP traffic within security group (required for Glue workers)
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow all TCP traffic within SG for Glue"
  }

  tags = {
    Name    = "${var.project_name}-sg-main"
    project = var.project_name
  }
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id
  ]

  tags = {
    Name    = "${var.project_name}-s3-endpoint"
    project = var.project_name
  }
}