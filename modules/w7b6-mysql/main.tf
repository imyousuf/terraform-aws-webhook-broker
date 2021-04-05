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

  identifier        = var.identifier
  engine            = "mysql"
  engine_version    = "8.0.21"
  instance_class    = var.db_instance_class
  allocated_storage = 5
  storage_encrypted = false

  name     = var.db_name
  username = var.db_username
  password = var.db_password
  port     = "3306"

  vpc_security_group_ids = [var.default_security_group_id, module.sg_mysql.this_security_group_id]

  maintenance_window = var.maintenance_window
  backup_window      = var.backup_window

  multi_az = true

  # disable backups to create DB faster
  backup_retention_period = 10

  tags = var.tags

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  # DB subnet group
  subnet_ids = var.subnets

  # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = var.final_snapshot_identifier

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
    },
    {
      name  = "transaction_isolation"
      value = "READ-COMMITTED"
    }
  ]

}
