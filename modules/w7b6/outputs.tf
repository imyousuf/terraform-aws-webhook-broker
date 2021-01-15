output "this_db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.mysql.this_db_instance_address
}

output "this_db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.mysql.this_db_instance_arn
}

output "this_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.mysql.this_db_instance_endpoint
}

output "this_db_instance_id" {
  description = "The RDS instance ID"
  value       = module.mysql.this_db_instance_id
}

output "this_db_instance_name" {
  description = "The database name"
  value       = module.mysql.this_db_instance_name
}

output "this_db_instance_username" {
  description = "The master username for the database"
  value       = module.mysql.this_db_instance_username
}
