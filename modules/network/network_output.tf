output "vpc_id" {
  value = aws_vpc.mercury_prod_vpc.id
  description = "Mercury Production VPC ID"
}

output "vpc_cidr_block" {
  value = aws_vpc.mercury_prod_vpc.cidr_block
  description = "Mercury Production VPC CIDR Blocks"
}

output "igw_id" {
  value = aws_internet_gateway.mercury_prod_igw.id
  description = "Mercury Production IGW ID"
}

output "ngw_id" {
  value = aws_nat_gateway.mercury_prod_ngw.id
  description = "Mercury Production NGW ID"
}

output "ngw_eip" {
  value = aws_eip.mercury_prod_ngw_eip.public_ip
  description = "Mercury Production NGW Public IP"
}

output "public_subnet_az1_id" { value = aws_subnet.mercury_az1_public.id }
output "public_subnet_az2_id" { value = aws_subnet.mercury_az2_public.id }
output "public_subnet_az3_id" { value = aws_subnet.mercury_az3_public.id }

output "private_subnet_apps_az1_id" { value = aws_subnet.mercury_az1_private_apps.id }
output "private_subnet_apps_az2_id" { value = aws_subnet.mercury_az2_private_apps.id }
output "private_subnet_apps_az3_id" { value = aws_subnet.mercury_az3_private_apps.id }

output "private_subnet_db_az1_id" { value = aws_subnet.mercury_az1_private_db.id }
output "private_subnet_db_az2_id" { value = aws_subnet.mercury_az2_private_db.id }
output "private_subnet_db_az3_id" { value = aws_subnet.mercury_az3_private_db.id }

output "private_subnets_app_cidr_list" {
  value = [
    "${resource.aws_subnet.mercury_az1_private_apps.cidr_block}",
    "${resource.aws_subnet.mercury_az2_private_apps.cidr_block}",
    "${resource.aws_subnet.mercury_az3_private_apps.cidr_block}"
  ]
}
