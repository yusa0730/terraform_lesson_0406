resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "${local.env}-private-a-rt"
  }
}

resource "aws_route_table" "private_c" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "${local.env}-private-c-rt"
  }
}

resource "aws_route_table_association" "private_a_route_table_association_with_nlb_private_a" {
  route_table_id = aws_route_table.private_a.id
  subnet_id      = aws_subnet.nlb_private_a.id
}

resource "aws_route_table_association" "private_a_route_table_association_with_ecs_private_a" {
  route_table_id = aws_route_table.private_a.id
  subnet_id      = aws_subnet.ecs_private_a.id
}

resource "aws_route_table_association" "private_c_route_table_association_with_nlb_private_c" {
  route_table_id = aws_route_table.private_c.id
  subnet_id      = aws_subnet.nlb_private_c.id
}

resource "aws_route_table_association" "private_c_route_table_association_with_ecs_private_c" {
  route_table_id = aws_route_table.private_c.id
  subnet_id      = aws_subnet.ecs_private_c.id
}
