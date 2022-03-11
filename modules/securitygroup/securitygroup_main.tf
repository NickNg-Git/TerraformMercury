## 1. Create Security Groups ## (7 SG - Application LB, React App, API App, DB, Bastion Host, Bastion Guest, Mailman)
resource "aws_security_group" "mercury_sg_applb" {
  name        = "Mercury Production SG - Application LB"
  description = "Allow TCP Inbound Traffic for Application LB"
  vpc_id      = "${var.vpc_id}"
  ingress {
    description      = "TCP from Public to LB for React App"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "TCP from Public to LB for API App"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Mercury-Prod-SG-AppLB"
  }
}

resource "aws_security_group" "mercury_sg_reactapp" {
  name        = "Mercury Production SG - React App"
  description = "Allow TCP Inbound Traffic for React App"
  vpc_id      = "${var.vpc_id}"
  ingress {
    description      = "TCP from VPC for React App"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups = ["${resource.aws_security_group.mercury_sg_applb.id}"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Mercury-Prod-SG-ReactApp"
  }
}

resource "aws_security_group" "mercury_sg_apiapp" {
  name        = "Mercury Production SG - API App"
  description = "Allow TCP Inbound Traffic for API App"
  vpc_id      = "${var.vpc_id}"
  ingress {
    description      = "TCP from VPC for API App"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups = ["${resource.aws_security_group.mercury_sg_applb.id}"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Mercury-Prod-SG-APIApp"
  }
}

resource "aws_security_group" "mercury_sg_db" {
  name        = "Mercury Production SG - DB"
  description = "Allow TCP Inbound Traffic for PostgresSQL"
  vpc_id      = "${var.vpc_id}"
  ingress {
    description      = "TCP from VPC for PostgresSQL"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups = ["${resource.aws_security_group.mercury_sg_apiapp.id}"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Mercury-Prod-SG-DB"
  }
}

resource "aws_security_group" "mercury_sg_mailman" {
  name        = "Mercury Production SG - Mailman"
  description = "Allow TCP Inbound Traffic for Mailman Services"
  vpc_id      = "${var.vpc_id}"
  ingress {
    description      = "TCP from VPC for Mailman REST"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups = ["${resource.aws_security_group.mercury_sg_apiapp.id}"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Mercury-Prod-SG-Mailman"
  }
}

resource "aws_security_group" "mercury_sg_bastionhost" {
  name        = "Mercury Production SG - Bastion Host"
  description = "Allow SSH Inbound Traffic for Bastion Hosts"
  vpc_id      = "${var.vpc_id}"
  ingress {
    description      = "SSH from Public for Bastion Hosts"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Mercury-Prod-SG-BastionHost"
  }
}

resource "aws_security_group" "mercury_sg_bastionguest" {
  name        = "Mercury Production SG - Bastion Guest"
  description = "Allow SSH Inbound Traffic for Bastion Guest"
  vpc_id      = "${var.vpc_id}"
  ingress {
    description      = "SSH from VPC for Bastion Guest"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups = ["${resource.aws_security_group.mercury_sg_bastionhost.id}"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Mercury-Prod-SG-BastionGuest"
  }
}