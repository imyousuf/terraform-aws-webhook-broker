resource "aws_security_group" "es" {
  count       = var.create_es ? 1 : 0
  name        = "elasticsearch-${var.es_domain}"
  description = "Managed by Terraform"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = var.sg_cidr_blocks
  }
}

resource "aws_iam_service_linked_role" "es" {
  count            = var.create_es ? 1 : 0
  aws_service_name = "es.amazonaws.com"
}

data "aws_caller_identity" "current" {}

resource "aws_elasticsearch_domain" "test_w7b6" {
  count                 = var.create_es ? 1 : 0
  domain_name           = var.es_domain
  elasticsearch_version = var.es_version
  cluster_config {
    instance_type          = var.es_instance_type
    instance_count         = var.use_3_az ? 3 : 2
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = var.use_3_az ? 3 : 2
    }
  }
  ebs_options {
    ebs_enabled = true
    volume_size = var.ebs_volume_size
  }
  vpc_options {
    subnet_ids         = var.subnets
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
            "Resource": "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${var.es_domain}/*"
        }
    ]
}
CONFIG

  tags = {
    Domain = "test-w7b6"
  }
  depends_on = [aws_iam_service_linked_role.es]
}
