variable "region" {
  default     = "us-east-1"
  description = "AWS Region"
}

variable "cluster_name" {
  default     = "test-w7b6"
  description = "AWS Region"
}

variable "k8s_version" {
  default     = "1.18"
  description = "EKS k8s version"
}

variable "subnets" {
  description = "Subnets to create the Kubernetes cluster in"
}

variable "vpc_id" {
  description = "VPC ID to create the Kubernetes cluster in"
}

variable "on_demand_desired_capacity" {
  default     = 1
  description = "On Demand Desired capacity"
}

variable "on_demand_min_size" {
  default     = 1
  description = "On Demand min size"
}

variable "on_demand_max_size" {
  default     = 2
  description = "On Demand max size"
}

variable "on_demand_instance_type" {
  default     = "c5.large"
  description = "On Demand Instance type"
}

variable "linux_ami" {
  default     = "ami-0e609024e4dbce4a5"
  description = "k8s optimized EC2 AMI ID - https://amzn.to/38G1Twv"
}

variable "spot_desired_capacity" {
  default     = 2
  description = "Spot Desired capacity"
}

variable "spot_max_size" {
  default     = 100
  description = "Spot max size"
}


variable "spot_instance_type" {
  default     = "c5.large"
  description = "Spot instance type"
}

variable "spot_instance_pools" {
  default     = 2
  description = "Number of spot instance pools"
}

variable "spot_max_price" {
  default     = "0.068"
  description = "The max price for a spot instance"
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Set the cluster endpoint to be available privately within a VPC"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Set the cluster endpoint to be available publicly"
}
