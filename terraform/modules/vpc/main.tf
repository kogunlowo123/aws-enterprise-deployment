# Enterprise VPC - 3-AZ Zero Trust Network
# Architect: Kehinde (Kenny) Samson Ogunlowo

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

data "aws_availability_zones" "available" { state = "available" }

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.common_tags, { Name = "${var.environment}-enterprise-vpc", Compliance = "NIST-800-53-SC-7" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.common_tags, { Name = "${var.environment}-igw" })
}

resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = merge(var.common_tags, {
    Name                                        = "${var.environment}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    Tier                                        = "Public"
  })
}

resource "aws_subnet" "private_app" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(var.common_tags, {
    Name                                        = "${var.environment}-private-app-${count.index + 1}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    Tier                                        = "Application"
  })
}

resource "aws_subnet" "private_data" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 6)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(var.common_tags, { Name = "${var.environment}-private-data-${count.index + 1}", Tier = "Data" })
}

resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"
  tags   = merge(var.common_tags, { Name = "${var.environment}-nat-eip-${count.index + 1}" })
}

resource "aws_nat_gateway" "main" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]
  tags          = merge(var.common_tags, { Name = "${var.environment}-nat-${count.index + 1}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0", gateway_id = aws_internet_gateway.main.id }
  tags = merge(var.common_tags, { Name = "${var.environment}-public-rt" })
}

resource "aws_route_table" "private_app" {
  count  = 3
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0", nat_gateway_id = aws_nat_gateway.main[count.index].id }
  tags = merge(var.common_tags, { Name = "${var.environment}-private-app-rt-${count.index + 1}" })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  tags = merge(var.common_tags, { Compliance = "HIPAA-164.312-b,CMMC-AU-2" })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.environment}"
  retention_in_days = 365
  tags              = var.common_tags
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.environment}-vpc-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "vpc-flow-logs.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private_app[*].id
  tags              = merge(var.common_tags, { Name = "${var.environment}-s3-endpoint" })
}
