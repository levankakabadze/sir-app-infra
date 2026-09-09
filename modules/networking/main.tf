# ==============================================================================
# DATA SOURCE
# =============================================================================

data "aws_region" "current" {}

# ==============================================================================
# VPC
# ==============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

# ==============================================================================
# SUBNETS
# ==============================================================================

resource "aws_subnet" "public" {
  for_each = var.public_subnet_cidrs

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = "eu-central-1${each.key}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.environment}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = var.private_subnet_cidrs

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "eu-central-1${each.key}"

  tags = {
    Name = "${var.project}-${var.environment}-private-${each.key}"
    Tier = "private"
  }
}

resource "aws_subnet" "isolated" {
  for_each = var.isolated_subnet_cidrs

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "eu-central-1${each.key}"

  tags = {
    Name = "${var.project}-${var.environment}-isolated-${each.key}"
    Tier = "isolated"
  }
}

# ==============================================================================
# Internet Gateway
# ==============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.environment}-igw"
  }
}

# ==============================================================================
# NAT Gateway
# ==============================================================================

resource "aws_eip" "nat" {
  for_each = toset(var.nat_gateway_azs)
  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.environment}-nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "main" {
  for_each = toset(var.nat_gateway_azs)
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${var.project}-${var.environment}-nat-gateway-${each.key}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ==============================================================================
# ROUTE TABLES
# ==============================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-rt-public"
  }
}

resource "aws_route_table" "private" {
  for_each = toset(var.nat_gateway_azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[each.key].id
  }

  tags = {
    Name = "${var.project}-${var.environment}-rt-private-${each.key}"
  }
}

resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.environment}-rt-isolated"
  }
}

# ==============================================================================
# ROUTE TABLE ASSOCIATIONS
# ==============================================================================

resource "aws_route_table_association" "public" {
  for_each = var.public_subnet_cidrs

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnet_cidrs

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[
    contains(tolist(var.nat_gateway_azs), each.key) ? each.key : tolist(toset(var.nat_gateway_azs))[0]
  ].id
}

resource "aws_route_table_association" "isolated" {
  for_each = var.isolated_subnet_cidrs

  subnet_id      = aws_subnet.isolated[each.key].id
  route_table_id = aws_route_table.isolated.id
}

# ==============================================================================
# VPC ENDPOINTS
# ==============================================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    values(aws_route_table.private)[*].id,
    [aws_route_table.isolated.id]
  )

  tags = {
    Name = "${var.project}-${var.environment}-s3-endpoint"
  }
}