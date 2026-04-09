# Elastic IP for NAT gateway
resource "aws_eip" "eip1" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-${var.project_name}-eip1"
  }
}

# NAT gateway for private subnet internet access
resource "aws_nat_gateway" "nat_gateway_az1" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.public_subnet_az1.id

  tags = {
    Name = "${var.environment}-${var.project_name}-natgw-az1"
  }

  # Ensure the NAT Gateway is created after the Internet Gateway
  depends_on = [aws_internet_gateway.internet_gateway]
}

# Private route table - routes traffic through NAT gateway
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_az1.id
  }

  tags = {
    Name = "${var.environment}-${var.project_name}-private-route-table"
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private_app_subnet_az1_rt_association" {
  subnet_id      = aws_subnet.private_app_subnet_az1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_app_subnet_az2_rt_association" {
  subnet_id      = aws_subnet.private_app_subnet_az2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_data_subnet_az1_rt_association" {
  subnet_id      = aws_subnet.private_data_subnet_az1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_data_subnet_az2_rt_association" {
  subnet_id      = aws_subnet.private_data_subnet_az2.id
  route_table_id = aws_route_table.private_route_table.id
}