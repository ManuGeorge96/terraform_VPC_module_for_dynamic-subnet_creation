#MANU GEORGE
###################################################################
#SECTION - 1
#####################################################################
resource "aws_vpc" "vpc-requestor" {
  cidr_block = var.cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project}-vpc"
    Project = "${var.project}"
  }
}
#################################################################
#SECTION - 2
##################################################################
locals {
  subnetr = floor(log((var.Public-Count + var.Private-Count) * 2,2))
}
resource "aws_subnet" "requestor-Public" {
  cidr_block = cidrsubnet(var.cidr, local.subnetr, "${count.index}")
  availability_zone = element(data.aws_availability_zones.AZ-requestor.names, count.index)
  vpc_id = aws_vpc.vpc-requestor.id
  map_public_ip_on_launch = true
  count = var.Public-Count
  tags = {
    Name = "${var.project}-Public-${count.index + 1}"
    Project = "${var.project}"
    Type = "Public"
  }
}

resource "aws_subnet" "requestor-Private" {
  count = var.Private-Count
  cidr_block = cidrsubnet(var.cidr, local.subnetr, "${count.index + var.Public-Count}")
  availability_zone = element(data.aws_availability_zones.AZ-requestor.names, count.index)
  vpc_id = aws_vpc.vpc-requestor.id
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-Private-${count.index + 1}"
    Project = "${var.project}"
    Type = "Private"
  }
}
#######################################################################
#SECTION- 3
#######################################################################
resource "aws_eip" "requestor-eip" {
  vpc = true
  count = var.Private-Count == "0" ? 0 : 1
  tags = {
    Name = "${var.project}-EIP"
    Project = "${var.project}"
  }
}
#######################################################################
#SECTION - 4
#######################################################################
resource "aws_nat_gateway" "requestor-NAT" {
  count = var.Private-Count == "0" ? 0 : 1
  allocation_id = aws_eip.requestor-eip[0].id
  subnet_id = aws_subnet.requestor-Public[0].id
  tags = {
    Name = "${var.project}-NAT"
    Project = "${var.project}"
  }
}
#######################################################################
#SECTION - 5
######################################################################
resource "aws_internet_gateway" "requestor-IGw" {
  vpc_id = aws_vpc.vpc-requestor.id
  tags = {
    Name = "${var.project}-IGW"
    Project = "${var.project}"
  }
}
#######################################################################
#SECTION - 6
########################################################################
resource "aws_route_table" "requestor-Public-RTB" {
  vpc_id = aws_vpc.vpc-requestor.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.requestor-IGw.id
  }
  tags = {
    Name = "${var.project}-Public-RTB"
    Project = "${var.project}"
    Type = "Public"
  }
}

resource "aws_route_table" "requestor-Private-RTB" {
  count = var.Private-Count == "0" ? 0 : 1
  vpc_id = aws_vpc.vpc-requestor.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.requestor-NAT[0].id
  }
  tags = {
    Name = "${var.project}-Private-RTB"
    Project = "${var.project}"
    Type = "Private"
  }
}
########################################################################
#SECTION - 7
########################################################################
resource "aws_route_table_association" "requestor-public" {
  count = "${length(aws_subnet.requestor-Public.*.cidr_block)}"
  subnet_id = "${element(aws_subnet.requestor-Public.*.id, count.index)}"
  route_table_id = aws_route_table.requestor-Public-RTB.id
}
resource "aws_route_table_association" "requestor-private" {
  count = "${length(aws_subnet.requestor-Private.*.cidr_block)}"
  subnet_id = "${element(aws_subnet.requestor-Private.*.id, count.index)}"
  route_table_id = aws_route_table.requestor-Private-RTB[0].id
}
#########################################################################
#SECTION - 8
#########################################################################
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.vpc-requestor.id
  subnet_ids = aws_subnet.requestor-Public.*.id

  egress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  tags = {
    Name = "${var.project}-NACL-Public"
    Project = "${var.project}"
    Type = "Public"
  }
}

resource "aws_network_acl" "private" {
  count = var.Private-Count == "0" ? 0 : 1
  vpc_id     = aws_vpc.vpc-requestor.id
  subnet_ids = aws_subnet.requestor-Private.*.id

  egress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  tags = {
    Name = "${var.project}-NACL-Private}"
    Project = "${var.project}"
    Type = "Private"
  }
}
