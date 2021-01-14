output "this_db_instance_address" {
  description = "The address of the RDS instance"
  value       = element(concat(module.rds.*.this_db_instance_address, list("")), 0)
}

output "this_db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = element(concat(module.rds.*.this_db_instance_arn, list("")), 0)
}

output "this_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = element(concat(module.rds.*.this_db_instance_endpoint, list("")), 0)
}

output "this_db_instance_id" {
  description = "The RDS instance ID"
  value       = element(concat(module.rds.*.this_db_instance_id, list("")), 0)
}

output "this_db_instance_name" {
  description = "The database name"
  value       = element(concat(module.rds.*.this_db_instance_name, list("")), 0)
}

output "this_db_instance_username" {
  description = "The master username for the database"
  value       = element(concat(module.rds.*.this_db_instance_username, list("")), 0)
}
