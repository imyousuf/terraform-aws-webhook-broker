variable "region" {
  default     = "us-east-1"
  description = "AWS Region"
}

variable "azs" {
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  description = "Availability Zones to use create the VPC"
}

variable "vpn_server_cert_arn" {
  default     = "arn:aws:acm:us-east-1:aws:certificate/cert-id"
  description = "The Server Certificate to use for Client VPN connectivity"
}

variable "vpn_client_cert_arn" {
  default     = "arn:aws:acm:us-east-1:aws:certificate/cert-id"
  description = "The Client Certificate to use for Client VPN connectivity authentication"
}

variable "create_rds" {
  default     = true
  description = "Whether to skip creating RDS"
}

variable "create_client_vpn" {
  default     = true
  description = "Whether to skip creating Client VPN"
}

variable "create_es" {
  default     = true
  description = "Whether to skip creating Elasticsearch"
}

variable "create_w7b6" {
  default     = true
  description = "Whether to skip creating Webhook Broker stack"
}

variable "db_password" {
  default     = "zxc90zxc"
  description = "RDS MySQL password for user `webhook_broker`"
}

variable "webhook_broker_https_cert_arn" {
  default     = "arn:aws:acm:us-east-1:aws:certificate/cert-id"
  description = "ALB HTTPS Certificate to use"
}

variable "webhook_broker_access_log_bucket" {
  default     = "some-bucket"
  description = "S3 bucket to store ALB Access Log"
}

variable "webhook_broker_log_bucket" {
  default     = "some-bucket"
  description = "S3 bucket for logs of EKS Containers, jobs, daemonsets"
}

variable "webhook_broker_access_log_path" {
  default     = "w7b6-access-log"
  description = "Path prefix to prepend before Access Log objects"
}

variable "webhook_broker_log_path" {
  default     = "w7b6-cluster-log"
  description = "Path prefix to prepend before EKS Log objects"
}

variable "webhook_broker_hostname" {
  default     = "one.test.w7b6.net"
  description = "The DNS Entry to associate with ALB; if there is already record set `external-dns` will not override it"
}

variable "map_users" {
  default = [
    {
      userarn  = "arn:aws:iam::<ACCOUNT_NUMBER>:user/<USER_NAME>"
      username = "<USER_NAME>"
      groups   = ["system:masters"]
    }
  ]
  description = "The users mapped for the kubernetes cluster"
}

variable "map_roles" {
  default = [
    {
      rolearn  = "arn:aws:iam::<ACCOUNT_NUMBER>:role/<ROLE_NAME>"
      username = "<ROLE_NAME>"
      groups   = ["system:masters"]
    },
  ]
  description = "The roles mapped for the kubernetes cluster"
}
