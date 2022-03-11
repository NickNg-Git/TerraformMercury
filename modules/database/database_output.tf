output "db_endpoint" {
  value = aws_db_instance.mercury_prod_db_instance.endpoint
  description = "Mercury Production DB Endpoint"
}

output "db_name" {
  value = aws_db_instance.mercury_prod_db_instance.name
  description = "Mercury Production DB Name"
}