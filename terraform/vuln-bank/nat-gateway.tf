resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-${var.project_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_az1.id

  tags = {
    Name = "${var.environment}-${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.environment}-${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_app_az1" {
  subnet_id      = aws_subnet.private_app_subnet_az1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_app_az2" {
  subnet_id      = aws_subnet.private_app_subnet_az2.id
  route_table_id = aws_route_table.private_route_table.id
}
