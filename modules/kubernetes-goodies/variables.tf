variable "region" {
  default     = "us-east-1"
  description = "AWS Region"
}

variable "cluster_oidc_issuer_url" {
  description = "AWS EKS Cluster OpenID Provider URL"
}

variable "cluster_id" {
  description = "AWS EKS Cluster ID"
}

variable "log_s3_bucket" {
  description = "S3 Bucket for Kubernetes Cluster Logs"
}

variable "log_s3_path_prefix" {
  description = "S3 Path Prefix for all log objects in S3"
}

variable "connect_es" {
  default     = true
  description = "Bool flag on whether to connect to Elasticsearch"
}

variable "es_url" {
  default     = ""
  description = "Elasticsearch URL to configure with AWS for Fluent Bit"
}

variable "additional_fluentbit_output" {
  default     = ""
  description = "If additional log output needs to be configured"
}

variable "vpc_id" {
  description = "VPC ID to create the Kubernetes cluster in"
}

variable "cluster_name" {
  default     = "test-w7b6"
  description = "AWS Region"
}

variable "k8s_dashboard_chart_values" {
  default     = []
  description = "Allow K8S Dashboard Chart to be configured from outside the module to add more configuration, e.g. Ingress annotation"
}
