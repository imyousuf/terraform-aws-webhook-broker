locals {
  k8s_w7b6_namespace = "webhook-broker"
}

module "mysql" {
  source                    = "../w7b6-mysql/"
  db_password               = var.db_password
  subnets                   = var.subnets
  vpc_id                    = var.vpc_id
  create                    = var.create && var.create_rds
  maintenance_window        = var.maintenance_window
  backup_window             = var.backup_window
  db_instance_class         = var.db_instance_class
  default_security_group_id = var.default_security_group_id
  sg_cidr_blocks            = var.sg_cidr_blocks
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
  version    = var.w7b6_chart_version

  depends_on = [module.mysql, kubernetes_namespace.webhook_broker_namespace]

  values = concat([templatefile("${path.module}/conf/webhook-broker-values.yml", { https_cert_arn = var.webhook_broker_https_cert_arn, db_url = var.create_rds ? "${module.mysql.this_db_instance_username}:${var.db_password}@tcp(${module.mysql.this_db_instance_endpoint})/${module.mysql.this_db_instance_name}?charset=utf8&parseTime=true&multiStatements=true" : var.db_url_override, access_log_s3_bucket = var.webhook_broker_access_log_bucket, access_log_s3_path_prefix = var.webhook_broker_access_log_path, subnets = join(", ", var.lb_subnets), hostname = var.webhook_broker_hostname })], var.override_webhook_broker_chart_config)
}
