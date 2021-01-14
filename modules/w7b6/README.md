# Webhook Broker (w7b6)

This module is responsible for installing Webhook Broker App Stack to an already existing EKS cluster. Please make sure to pass in the following variables at least -

```terraform
    subnets                          = module.vpc.database_subnets
    vpc_id                           = module.vpc.vpc_id
    default_security_group_id        = module.vpc.default_security_group_id
    sg_cidr_blocks                   = [local.vpc_cidr_block, local.vpn_cidr_block]
    lb_subnets                       = module.vpc.private_subnets
    webhook_broker_https_cert_arn    = "arn:aws:acm:<REGION>:<ACCOUNT_ID>:certificate/<HTTPS_CERT_FOR_HOSTNAME>"
    webhook_broker_access_log_bucket = "logs-bucket"
    webhook_broker_access_log_path   = "path-prefix"
    webhook_broker_hostname          = "match-hostname-to-certificate"
```

Default chart values also assume that the EKS cluster has at least following services installed -

1. AWS ALB Ingress Controller
1. External DNS Controller

The default chart also configures Horizontal Pod Autoscaling, so please consider having that setup properly as well.
