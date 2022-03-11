output "sg_applb_id" {
  value = aws_security_group.mercury_sg_applb.id
  description = "Mercury Production SG - Application LB"
}

output "sg_reactapp_id" {
  value = aws_security_group.mercury_sg_reactapp.id
  description = "Mercury Production SG - React App"
}

output "sg_apiapp_id" {
  value = aws_security_group.mercury_sg_apiapp.id
  description = "Mercury Production SG - API App"
}

output "sg_db_id" {
  value = aws_security_group.mercury_sg_db.id
  description = "Mercury Production SG - DB"
}

output "sg_mailman_id" {
  value = aws_security_group.mercury_sg_mailman.id
  description = "Mercury Production SG - Mailman"
}

output "sg_bastionhost_id" {
  value = aws_security_group.mercury_sg_bastionhost.id
  description = "Mercury Production SG - Bastion Host"
}

output "sg_bastionguest_id" {
  value = aws_security_group.mercury_sg_bastionguest.id
  description = "Mercury Production SG - Bastion Guest"
}