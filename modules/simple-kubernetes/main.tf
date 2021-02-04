terraform {
  required_version = ">= 0.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.22.0"
    }
  }
}

locals {
  asg_tags = [
    {
      "key"                 = "k8s.io/cluster-autoscaler/enabled"
      "propagate_at_launch" = "false"
      "value"               = "true"
    },
    {
      "key"                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
      "propagate_at_launch" = "false"
      "value"               = "true"
    }
  ]
}

module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "13.2.1"
  cluster_name                    = var.cluster_name
  cluster_version                 = var.k8s_version
  subnets                         = var.subnets
  vpc_id                          = var.vpc_id
  enable_irsa                     = true
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  map_users                       = var.map_users
  map_roles                       = var.map_roles

  worker_groups = [
    {
      name                 = "worker-group-1"
      asg_desired_capacity = var.on_demand_desired_capacity
      asg_min_size         = var.on_demand_min_size
      asg_max_size         = var.on_demand_max_size
      instance_type        = var.on_demand_instance_type
      ami_id               = var.linux_ami
      tags                 = local.asg_tags
    },
    {
      name                     = "worker-spot-group-1"
      asg_desired_capacity     = var.spot_desired_capacity
      asg_max_size             = var.spot_max_size
      kubelet_extra_args       = "--node-labels=node.kubernetes.io/lifecycle=spot"
      instance_type            = var.spot_instance_type
      ami_id                   = var.linux_ami
      spot_instance_pools      = var.spot_instance_pools
      spot_allocation_strategy = "lowest-price" # Valid options are 'lowest-price' and 'capacity-optimized'. If 'lowest-price', the Auto Scaling group launches instances using the Spot pools with the lowest price, and evenly allocates your instances across the number of Spot pools. If 'capacity-optimized', the Auto Scaling group launches instances using Spot pools that are optimally chosen based on the available Spot capacity.
      spot_price               = var.spot_max_price
      tags                     = local.asg_tags
    }
  ]
}
