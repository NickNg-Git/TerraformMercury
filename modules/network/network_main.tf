## 1. Create VPC ##
resource "aws_vpc" "mercury_prod_vpc" {
  cidr_block = "10.18.0.0/16"
  tags = {
    Name = "Mercury Production VPC"
  }
}

## 2. Create Internet Gateway ##
resource "aws_internet_gateway" "mercury_prod_igw" {
  vpc_id = aws_vpc.mercury_prod_vpc.id
  tags = {
    Name = "Mercury Production IGW"
  }
}

## 3. Create Subnet ##
### Public Subnets - 3 AZ ###
resource "aws_subnet" "mercury_az1_public" {
  vpc_id     = aws_vpc.mercury_prod_vpc.id
  cidr_block = "10.18.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "Mercury Production Public AZ1"
  }
}
resource "aws_subnet" "mercury_az2_public" {
  vpc_id     = aws_vpc.mercury_prod_vpc.id
  cidr_block = "10.18.2.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "Mercury Production Public AZ2"
  }
}
resource "aws_subnet" "mercury_az3_public" {
  vpc_id     = aws_vpc.mercury_prod_vpc.id
  cidr_block = "10.18.3.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "Mercury Production Public AZ3"
  }
}

### Private Subnets (Applications) - 3 AZ ###
resource "aws_subnet" "mercury_az1_private_apps" {
  vpc_id     = aws_vpc.mercury_prod_vpc.id
  cidr_block = "10.18.10.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "Mercury Production Private AZ1 - Applications"
  }
}
resource "aws_subnet" "mercury_az2_private_apps" {
  vpc_id     = aws_vpc.mercury_prod_vpc.id
  cidr_block = "10.18.20.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "Mercury Production Private AZ2 - Applications"
  }
}
resource "aws_subnet" "mercury_az3_private_apps" {
  vpc_id     = aws_vpc.mercury_prod_vpc.id
  cidr_block = "10.18.30.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "Mercury Production Private AZ3 - Applications"
  }
}

### Private Subnets (DB) - 3 AZ ###
resource "aws_subnet" "mercury_az1_private_db" {
  vpc_id     = aws_vpc.mercury_prod_vpc.id
  cidr_block = "10.18.40.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "Mercury Production Private AZ1 - DB"
  }
}
resource "aws_subnet" "mercury_az2_private_db" {
  vpc_id     = aws_vpc.mercury_prod_vpc.id
  cidr_block = "10.18.50.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "Mercury Production Private AZ2 - DB"
  }
}
resource "aws_subnet" "mercury_az3_private_db" {
  vpc_id     = aws_vpc.mercury_prod_vpc.id
  cidr_block = "10.18.60.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "Mercury Production Private AZ3 - DB"
  }
}

## 4. Create EIP ##
resource "aws_eip" "mercury_prod_ngw_eip" {
  vpc = true
  depends_on = [aws_internet_gateway.mercury_prod_igw]
  tags = {
    Name = "Mercury Production NGW EIP"
  }
}

## 5. Create NAT Gateway ##
resource "aws_nat_gateway" "mercury_prod_ngw" {
  connectivity_type = "public"
  allocation_id = aws_eip.mercury_prod_ngw_eip.id
  subnet_id     = aws_subnet.mercury_az3_public.id
  tags = {
    Name = "Mercury Production NGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.mercury_prod_igw]
}

## 6. Create Route Tables ##
resource "aws_route_table" "mercury_prod_public_routetable" {
  vpc_id = aws_vpc.mercury_prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mercury_prod_igw.id
  }

  tags = {
    Name = "Mercury Production Public Route Table - IGW"
  }
}
resource "aws_route_table" "mercury_prod_private_routetable" {
  vpc_id = aws_vpc.mercury_prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.mercury_prod_ngw.id
  }

  tags = {
    Name = "Mercury Production Private Route Table - NGW"
  }
}

## 7. Create Route Table Association ##
### Associate Public Route Table with Public Subnets ###
resource "aws_route_table_association" "mercury_az1_public_routetable_association" {
  subnet_id      = aws_subnet.mercury_az1_public.id
  route_table_id = aws_route_table.mercury_prod_public_routetable.id
}
resource "aws_route_table_association" "mercury_az2_public_routetable_association" {
  subnet_id      = aws_subnet.mercury_az2_public.id
  route_table_id = aws_route_table.mercury_prod_public_routetable.id
}
resource "aws_route_table_association" "mercury_az3_public_routetable_association" {
  subnet_id      = aws_subnet.mercury_az3_public.id
  route_table_id = aws_route_table.mercury_prod_public_routetable.id
}

### Associate Private Route Table with Private Subnets ###
resource "aws_route_table_association" "mercury_az1_private_apps_routetable_association" {
  subnet_id      = aws_subnet.mercury_az1_private_apps.id
  route_table_id = aws_route_table.mercury_prod_private_routetable.id
}
resource "aws_route_table_association" "mercury_az2_private_apps_routetable_association" {
  subnet_id      = aws_subnet.mercury_az2_private_apps.id
  route_table_id = aws_route_table.mercury_prod_private_routetable.id
}
resource "aws_route_table_association" "mercury_az3_private_apps_routetable_association" {
  subnet_id      = aws_subnet.mercury_az3_private_apps.id
  route_table_id = aws_route_table.mercury_prod_private_routetable.id
}

resource "aws_route_table_association" "mercury_az1_private_db_routetable_association" {
  subnet_id      = aws_subnet.mercury_az1_private_db.id
  route_table_id = aws_route_table.mercury_prod_private_routetable.id
}
resource "aws_route_table_association" "mercury_az2_private_db_routetable_association" {
  subnet_id      = aws_subnet.mercury_az2_private_db.id
  route_table_id = aws_route_table.mercury_prod_private_routetable.id
}
resource "aws_route_table_association" "mercury_az3_private_db_routetable_association" {
  subnet_id      = aws_subnet.mercury_az3_private_db.id
  route_table_id = aws_route_table.mercury_prod_private_routetable.id
}