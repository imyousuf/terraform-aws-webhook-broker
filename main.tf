provider "aws" {
  region = var.region
}

locals {
  cluster_name       = "test-eks-w7b6"
  es_domain          = "test-es-w7b6"
  vpc_cidr_block     = "20.10.0.0/16"
  vpn_cidr_block     = "17.10.0.0/16"
  k8s_w7b6_namespace = "webhook-broker"
}

# VPC and Client VPN

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.64.0"

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
  source = "./modules/client-vpn/"

  vpc_id              = module.vpc.vpc_id
  vpn_cidr            = local.vpn_cidr_block
  private_subnets     = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  vpn_server_cert_arn = var.vpn_server_cert_arn
  vpn_client_cert_arn = var.vpn_client_cert_arn
  region              = var.region
}

# Elasticsearch for log ingestion

resource "aws_security_group" "es" {
  count       = var.create_es ? 1 : 0
  name        = "elasticsearch-${local.es_domain}"
  description = "Managed by Terraform"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      local.vpc_cidr_block, local.vpn_cidr_block
    ]
  }
}

resource "aws_iam_service_linked_role" "es" {
  count            = var.create_es ? 1 : 0
  aws_service_name = "es.amazonaws.com"
}

data "aws_caller_identity" "current" {}

resource "aws_elasticsearch_domain" "test_w7b6" {
  count                 = var.create_es ? 1 : 0
  domain_name           = local.es_domain
  elasticsearch_version = "7.9"
  cluster_config {
    instance_type          = "t2.medium.elasticsearch"
    instance_count         = 3
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 3
    }
  }
  ebs_options {
    ebs_enabled = true
    volume_size = 35
  }
  vpc_options {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.es[0].id]
  }
  domain_endpoint_options {
    enforce_https       = false
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${local.es_domain}/*"
        }
    ]
}
CONFIG

  tags = {
    Domain = "test-w7b6"
  }
  depends_on = [aws_iam_service_linked_role.es]
}

# EKS

module "eks" {
  source       = "./modules/simple-kubernetes/"
  region       = var.region
  cluster_name = local.cluster_name
  subnets      = module.vpc.public_subnets
  vpc_id       = module.vpc.vpc_id
}

# Kubernetes and Helm Setup

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

module "goodies" {
  source                  = "./modules/kubernetes-goodies/"
  depends_on              = [module.eks, aws_elasticsearch_domain.test_w7b6]
  region                  = var.region
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  cluster_id              = module.eks.cluster_id
  log_s3_bucket           = var.webhook_broker_log_bucket
  log_s3_path_prefix      = var.webhook_broker_log_path
  connect_es              = var.create_es
  cluster_name            = local.cluster_name
  es_url                  = element(concat(aws_elasticsearch_domain.test_w7b6.*.endpoint, list("")), 0)
  vpc_id                  = module.vpc.vpc_id
}

# Webhook Broker

module "webhook_broker" {
  source     = "./modules/w7b6/"
  depends_on = [module.goodies]

  subnets                          = module.vpc.database_subnets
  vpc_id                           = module.vpc.vpc_id
  create                           = var.create_w7b6
  default_security_group_id        = module.vpc.default_security_group_id
  sg_cidr_blocks                   = [local.vpc_cidr_block, local.vpn_cidr_block]
  webhook_broker_https_cert_arn    = var.webhook_broker_https_cert_arn
  webhook_broker_access_log_bucket = var.webhook_broker_access_log_bucket
  webhook_broker_access_log_path   = var.webhook_broker_access_log_path
  lb_subnets                       = module.vpc.private_subnets
  webhook_broker_hostname          = var.webhook_broker_hostname
}
