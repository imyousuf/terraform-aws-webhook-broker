variable "region" {
  default     = "us-east-1"
  description = "AWS Region"
}

variable "es_domain" {
  default     = "test-es-w7b6"
  description = "Elasticsearch domain name to launch one by"
}

variable "create_es" {
  default     = true
  description = "Whether to skip creating es"
}

variable "vpc_id" {
  description = "VPC ID to create the Kubernetes cluster in"
}

variable "sg_cidr_blocks" {
  default     = []
  description = "CIDR Blocks that will be allowed to access the RDS instance"
}

variable "subnets" {
  description = "Subnets to create the Kubernetes cluster in"
}

variable "use_3_az" {
  default     = true
  description = "Whether to use 3 AZs instead of 2"
}

variable "es_version" {
  default     = "7.9"
  description = "Version of Elasticsearch to use"
}

variable "ebs_volume_size" {
  default     = 35
  description = "Default EBS Volume size to add to ES instances"
}

variable "es_instance_type" {
  default     = "t2.medium.elasticsearch"
  description = "ES Instance type to use"
}
