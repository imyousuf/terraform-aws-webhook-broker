variable "db_password" {
  default     = "zxc90zxc"
  description = "RDS MySQL password for user `webhook_broker`"
}
variable "db_username" {
  default     = "webhook_broker"
  description = "RDS MySQL username for user"
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

variable "webhook_broker_https_cert_arn" {
  default     = "arn:aws:acm:us-east-1:aws:certificate/cert-id"
  description = "ALB HTTPS Certificate to use"
}

variable "webhook_broker_access_log_bucket" {
  default     = "some-bucket"
  description = "S3 bucket to store ALB Access Log"
}

variable "webhook_broker_access_log_path" {
  default     = "w7b6-access-log"
  description = "Path prefix to prepend before Access Log objects"
}

variable "lb_subnets" {
  default     = []
  description = "Subnets to spin up ALB in"
}

variable "webhook_broker_hostname" {
  default     = "one.test.w7b6.net"
  description = "The DNS Entry to associate with ALB; if there is already record set `external-dns` will not override it"
}

variable "override_webhook_broker_chart_config" {
  default     = []
  description = "Custom Webhook Broker Chart configuration which will override the default chart config"
}

variable "create_rds" {
  default     = true
  description = "Whether to create RDS and its applicable only `create` is true. Also if this is false but `create` is true, code will use `db_url_override` instead"
}

variable "db_url_override" {
  default     = ""
  description = "Custom Webhook Broker Chart configuration which will override the default chart config"
}

variable "w7b6_chart_version" {
  default     = "0.1.0-beta-1"
  description = "Custom Webhook Broker Chart configuration which will override the default chart config"
}
