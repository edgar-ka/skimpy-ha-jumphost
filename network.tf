
data "aws_availability_zones" "this_zones" {
  state = "available"
}

resource "aws_vpc" "this_vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name      = "${local.prefix}-vpc"
    Terraform = true
  }
}

resource "aws_subnet" "this_subnets" {
  vpc_id            = aws_vpc.this_vpc.id
  count             = length(data.aws_availability_zones.this_zones.names)
  availability_zone = element(data.aws_availability_zones.this_zones.names, count.index)
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, count.index + 1)

  tags = {
    Name      = "${random_pet.nikname.id}-subnet-${count.index + 1}"
    Terraform = true
  }
}

resource "aws_internet_gateway" "this_igw" {
  vpc_id = aws_vpc.this_vpc.id

  tags = {
    Name      = "${local.prefix}-igw"
    Terraform = true
  }
}

resource "aws_route_table" "this_rt" {
  vpc_id = aws_vpc.this_vpc.id
  depends_on = [
    aws_internet_gateway.this_igw
  ]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this_igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.this_igw.id
  }

  tags = {
    Name      = "${local.prefix}-rt"
    Terraform = true
  }
}

resource "aws_route_table_association" "this_rta" {
  count          = length(data.aws_availability_zones.this_zones.names)
  subnet_id      = aws_subnet.this_subnets[count.index].id
  route_table_id = aws_route_table.this_rt.id
}

resource "aws_security_group" "this_sg" {
  name   = "${local.prefix}-sg"
  vpc_id = aws_vpc.this_vpc.id

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${local.prefix}-sg"
    Terraform = true
  }
}
