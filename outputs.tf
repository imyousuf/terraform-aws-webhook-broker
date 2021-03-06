# Region
output "region" {
  description = "AWS region."
  value       = var.region
}

# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

# VPN
output "vpn_id" {
  value       = element(concat(module.client_vpn.*.vpn_id, list("")), 0)
  description = "Client VPN AWS ID"
}

# Elasticsearch
output "es_endpoint" {
  value       = module.simple_es.es_endpoint
  description = "Elasticsearch API Endpoint"
}

output "es_kibana" {
  value       = module.simple_es.es_kibana
  description = "Elasticsearch Kibana URL"
}

# RDS
output "this_db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.webhook_broker.this_db_instance_address
}

output "this_db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.webhook_broker.this_db_instance_arn
}

output "this_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.webhook_broker.this_db_instance_endpoint
}

output "this_db_instance_id" {
  description = "The RDS instance ID"
  value       = module.webhook_broker.this_db_instance_id
}

output "this_db_instance_name" {
  description = "The database name"
  value       = module.webhook_broker.this_db_instance_name
}

output "this_db_instance_username" {
  description = "The master username for the database"
  value       = module.webhook_broker.this_db_instance_username
}

# EKS
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config" {
  description = "kubectl config as generated by the module."
  value       = module.eks.kubectl_config
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = module.eks.config_map_aws_auth
}
