# Base isolated network for all resources
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# Public subnets for internet-facing resources (ALB, NAT)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.current.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private subnets for internal resources (EKS nodes, RDS)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.current.names[count.index]

  tags = {
    Name = "${var.app_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Enables internet access for public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

# Static IP used by NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.app_name}-nat-eip"
  }
}

# Allows private subnets to reach the internet via NAT
resource "aws_nat_gateway" "main" {
  depends_on    = [aws_internet_gateway.main]
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.app_name}-nat-gateway"
  }
}

# Route table for public subnets (direct internet access)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-public-route-table"
  }
}

# Route table for private subnets (outbound via NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-private-route-table"
  }
}

# Public route sends traffic to Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Private route sends traffic through NAT Gateway
resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# Attach public subnets to public route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Attach private subnets to private route table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security group for EKS / app (public API access)
resource "aws_security_group" "eks" {
  name        = "${var.app_name}-eks-sg"
  description = "Allow HTTP/HTTPS inbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-eks-sg"
  }
}

# Allow HTTP/HTTPS from internet to app
resource "aws_vpc_security_group_ingress_rule" "eks_http_https" {
  security_group_id = aws_security_group.eks.id
  from_port         = 80
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# Allow all outbound traffic from app
resource "aws_vpc_security_group_egress_rule" "eks_all_outbound" {
  security_group_id = aws_security_group.eks.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Security group for RDS (private database access)
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-sg"
  description = "Allow MySQL access from EKS only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-rds-sg"
  }
}

# Allow MySQL access ONLY from EKS security group
resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_eks" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.eks.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

# Allow outbound traffic from RDS (default behavior)
resource "aws_vpc_security_group_egress_rule" "rds_all_outbound" {
  security_group_id = aws_security_group.rds.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}