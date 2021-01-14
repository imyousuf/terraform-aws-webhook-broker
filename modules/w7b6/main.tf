locals {
  k8s_w7b6_namespace = "webhook-broker"
}

# RDS

module "sg_mysql" {
  source  = "terraform-aws-modules/security-group/aws//modules/mysql"
  version = "3.17.0"
  name    = "security-group-mysql-${var.vpc_id}"
  vpc_id  = var.vpc_id

  create = var.create

  ingress_cidr_blocks = var.sg_cidr_blocks
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "2.20.0"

  create_db_instance = var.create

  identifier        = "w7b6"
  engine            = "mysql"
  engine_version    = "8.0.21"
  instance_class    = var.db_instance_class
  allocated_storage = 5
  storage_encrypted = false

  name     = "webhook_broker"
  username = "webhook_broker"
  password = var.db_password
  port     = "3306"

  vpc_security_group_ids = [var.default_security_group_id, module.sg_mysql.this_security_group_id]

  maintenance_window = var.maintenance_window
  backup_window      = var.backup_window

  multi_az = true

  # disable backups to create DB faster
  backup_retention_period = 10

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  # DB subnet group
  subnet_ids = var.subnets

  # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "w7b6snap"

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]

}

resource "kubernetes_namespace" "webhook_broker_namespace" {
  count = var.create ? 1 : 0
  metadata {
    name = local.k8s_w7b6_namespace
  }
}

resource "helm_release" "webhook-broker" {
  count     = var.create ? 1 : 0
  name      = "webhook-broker"
  namespace = local.k8s_w7b6_namespace

  repository = "https://helm.imytech.net/"
  chart      = "webhook-broker-chart"
  version    = "0.1.0-dev"

  depends_on = [module.rds, kubernetes_namespace.webhook_broker_namespace]

  values = concat([templatefile("${path.module}/conf/webhook-broker-values.yml", { https_cert_arn = var.webhook_broker_https_cert_arn, db_url = "${module.rds.this_db_instance_username}:${var.db_password}@tcp(${module.rds.this_db_instance_endpoint})/${module.rds.this_db_instance_name}?charset=utf8&parseTime=true&multiStatements=true", access_log_s3_bucket = var.webhook_broker_access_log_bucket, access_log_s3_path_prefix = var.webhook_broker_access_log_path, subnets = join(", ", var.lb_subnets), hostname = var.webhook_broker_hostname })], var.override_webhook_broker_chart_config)
}
