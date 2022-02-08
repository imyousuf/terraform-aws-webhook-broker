provider "aws" {
  region = var.region
}

locals {
  cluster_name   = "test-eks-w7b6"
  vpc_cidr_block = "20.10.0.0/16"
  vpn_cidr_block = "17.10.0.0/16"
  db_password    = "zxc90zxc"
  db_username    = "webhook_broker"
}

# VPC and Client VPN

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.12.0"

  name = "webhook-broker-vpc"

  cidr = local.vpc_cidr_block # 10.0.0.0/8 is reserved for EC2-Classic

  azs              = var.azs
  private_subnets  = ["20.10.1.0/24", "20.10.2.0/24", "20.10.3.0/24"]
  public_subnets   = ["20.10.11.0/24", "20.10.12.0/24", "20.10.13.0/24"]
  database_subnets = ["20.10.21.0/24", "20.10.22.0/24", "20.10.23.0/24"]

  private_subnet_tags = { "kubernetes.io/role/internal-elb" : "1" }
  public_subnet_tags  = { "kubernetes.io/role/elb" : "1" }

  create_database_subnet_group = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_classiclink             = true
  enable_classiclink_dns_support = true

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_vpn_gateway = true

  enable_dhcp_options      = true
  dhcp_options_domain_name = "ec2.internal"

  # Default security group - ingress/egress rules cleared to deny all
  manage_default_security_group  = true
  default_security_group_ingress = [{}]
  default_security_group_egress  = [{ from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = "0.0.0.0/0" }]

  tags = {
    Owner       = "user"
    Environment = "staging"
    Name        = "webhook-broker"
  }

  vpc_endpoint_tags = {
    Project  = "Secret"
    Endpoint = "true"
  }
}

module "client_vpn" {
  source              = "./modules/client-vpn/"
  count               = var.create_client_vpn ? 1 : 0
  vpc_id              = module.vpc.vpc_id
  vpn_cidr            = local.vpn_cidr_block
  private_subnets     = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  vpn_server_cert_arn = var.vpn_server_cert_arn
  vpn_client_cert_arn = var.vpn_client_cert_arn
  region              = var.region
}

# Elasticsearch for log ingestion

module "simple_es" {
  source         = "./modules/simple-log-es/"
  region         = var.region
  create_es      = var.create_es
  vpc_id         = module.vpc.vpc_id
  sg_cidr_blocks = [local.vpc_cidr_block, local.vpn_cidr_block]
  subnets        = module.vpc.private_subnets
  tags = {
    Domain = "test-w7b6"
  }
}

# EKS

module "eks" {
  source                          = "./modules/simple-kubernetes/"
  region                          = var.region
  cluster_name                    = local.cluster_name
  subnets                         = module.vpc.public_subnets
  vpc_id                          = module.vpc.vpc_id
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true
  map_users                       = var.map_users
  map_roles                       = var.map_roles
}

# RDS

module "webhook_broker_db" {
  source                    = "./modules/w7b6-mysql/"
  subnets                   = module.vpc.database_subnets
  vpc_id                    = module.vpc.vpc_id
  create                    = var.create_w7b6
  default_security_group_id = module.vpc.default_security_group_id
  sg_cidr_blocks            = [local.vpc_cidr_block, local.vpn_cidr_block]
  identifier                = "w7b6"
  final_snapshot_identifier = "w7b6snap"
  db_name                   = "webhook_broker"
  db_username               = local.db_username
  db_password               = local.db_password
  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

# Kubernetes and Helm Setup

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
      command     = "aws"
    }
  }
}

# Useful Kubernetes Services

module "goodies" {
  source                  = "./modules/kubernetes-goodies/"
  region                  = var.region
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  cluster_id              = module.eks.cluster_id
  log_s3_bucket           = var.webhook_broker_log_bucket
  log_s3_path_prefix      = var.webhook_broker_log_path
  connect_es              = var.create_es
  cluster_name            = local.cluster_name
  es_url                  = module.simple_es.es_endpoint
  vpc_id                  = module.vpc.vpc_id
}

# Webhook Broker

module "webhook_broker" {
  source                           = "./modules/w7b6/"
  depends_on                       = [module.goodies]
  subnets                          = module.vpc.database_subnets
  vpc_id                           = module.vpc.vpc_id
  db_password                      = local.db_password
  create                           = var.create_w7b6
  create_rds                       = false
  default_security_group_id        = module.vpc.default_security_group_id
  sg_cidr_blocks                   = [local.vpc_cidr_block, local.vpn_cidr_block]
  webhook_broker_https_cert_arn    = var.webhook_broker_https_cert_arn
  webhook_broker_access_log_bucket = var.webhook_broker_access_log_bucket
  webhook_broker_access_log_path   = var.webhook_broker_access_log_path
  lb_subnets                       = module.vpc.private_subnets
  webhook_broker_hostname          = var.webhook_broker_hostname
  db_url_override                  = "${module.webhook_broker_db.this_db_instance_username}:${local.db_password}@tcp(${module.webhook_broker_db.this_db_instance_endpoint})/${module.webhook_broker_db.this_db_instance_name}?charset=utf8&parseTime=true&multiStatements=true"
}
