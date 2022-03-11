resource "aws_db_subnet_group" "mercury_prod_db_subnet_group" {
  name       = "${var.db_subnet_group_name}"
  subnet_ids = var.subnet_groups
  tags = {
    Name = "${var.db_subnet_group_tagname}"
  }
}

resource "aws_db_instance" "mercury_prod_db_instance" {
  name                = "${var.db_name}"
  engine              = "postgres"
  engine_version      = "13.4"
  identifier          = "${var.db_identifier}"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  vpc_security_group_ids = var.security_groups
  username            = "postgres"
  password            = "postgres"
  multi_az            = var.multi_az
  skip_final_snapshot = true
  publicly_accessible = var.publicly_accessible
  db_subnet_group_name = "${resource.aws_db_subnet_group.mercury_prod_db_subnet_group.id}"
  storage_encrypted   = true
  kms_key_id          = "${var.kms_key_arn}"
}