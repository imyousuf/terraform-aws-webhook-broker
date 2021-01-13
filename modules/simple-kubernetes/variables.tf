variable "region" {
  default     = "us-east-1"
  description = "AWS Region"
}

variable "cluster_name" {
  default     = "test-w7b6"
  description = "AWS Region"
}

variable "subnets" {
  description = "Subnets to create the Kubernetes cluster in"
}

variable "vpc_id" {
  description = "VPC ID to create the Kubernetes cluster in"
}

variable "k8s_version" {
  default     = "1.18"
  description = "EKS k8s version"
}

variable "on_demand_instance_type" {
  default     = "c5.large"
  description = "On Demand Instance type"
}

variable "on_demand_max_size" {
  default     = "2"
  description = "On Demand Instance type"
}

variable "spot_instance_type" {
  default     = "c5.large"
  description = "AWS Region"
}

variable "spot_max_price" {
  default     = "0.068"
  description = ""
}

variable "linux_ami" {
  default     = "ami-0e609024e4dbce4a5"
  description = "k8s optimized EC2 AMI ID - https://amzn.to/38G1Twv"
}
