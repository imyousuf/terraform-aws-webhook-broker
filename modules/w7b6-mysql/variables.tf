variable "db_password" {
  default     = "zxc90zxc"
  description = "RDS MySQL password for user `webhook_broker`"
}

variable "identifier" {
  description = "The identifier of the webhook broker"
}
variable "db_username" {
  description = "Username of DB"
}
variable "db_name" {
  description = "Name of the database"
}
variable "final_snapshot_identifier" {
  description = "Name of final snapshot"
}

variable "tags" {
  description = "Tags to add to db"
}

variable "subnets" {
  description = "Subnets to create the Kubernetes cluster in"
}

variable "vpc_id" {
  description = "VPC ID to create the Kubernetes cluster in"
}

variable "create" {
  default     = true
  description = "Whether to create webhook broker stack"
}

variable "maintenance_window" {
  default     = "Sun:00:00-Sun:03:00"
  description = "Maintenance Window for MySQL RDS configuration"
}

variable "backup_window" {
  default     = "04:00-07:00"
  description = "Backup Window for RDS to use to backup the DB"
}

variable "db_instance_class" {
  default     = "db.r5.large"
  description = "RDS Instance class"
}

variable "default_security_group_id" {
  description = "The Default Security Group ID of the VPC or any other SG; there will be an SG created for the CIDR block supplied in variable section"
}

variable "sg_cidr_blocks" {
  default     = []
  description = "CIDR Blocks that will be allowed to access the RDS instance"
}
