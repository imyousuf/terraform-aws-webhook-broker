# AWS Infrastructure for [Webhook Broker](https://github.com/imyousuf/webhook-broker)

This Terraform configuration provides a infrastructure as a code for [Webhook Broker](https://github.com/imyousuf/webhook-broker) in AWS.

## What does it do?

The goal is to launch a full stack of Webhook Broker; which includes -

1. VPC in 3 availability zone with 3 subnets for public, private and database
1. AWS Client VPC to connect to the resources in private network of the VPC
1. AWS EKS using on demand and spot instances launch configuration with ASG
1. Set of Kubernetes services deployed for cluster management and sidecar functionality to other apps

    1. AWS Instance Termination Handler
    1. Cluster Autoscaler to scale cluster dynamically
    1. Kubernetes Dashboard with Metrics Scrapper
    1. `metrics-server` to make Horizontal Pod Autoscaling (HPA) to work
    1. `external-dns` for assigning Route53 DNS to Ingress services.
    1. AWS ALB Ingress Controller
    1. AWS for Fluent Bit

1. Elasticsearch for app log indexing (can be skipped)
1. Webhook Broker stack

    1. AWS RDS
    1. Webhook Broker with AWS ALB and Route53 DNS set

All the services installed in EKS are done through [Helm Charts](https://helm.sh/).

## Usage

Firstly start by making sure AWS CLI is installed and configured properly. Then please make sure to create a `custom_vars.auto.tfvars` file with the following variables to use Client VPN [module](https://github.com/imyousuf/terraform-aws-webhook-broker/blob/main/modules/client-vpn/README.md).

```terraform
vpn_server_cert_arn = "arn:aws:acm:<REGION>:<ACCOUNT_ID>:certificate/<CERT_ARN_FOR_SERVER>"
vpn_client_cert_arn = "arn:aws:acm:<REGION>:<ACCOUNT_ID>:certificate/<CERT_ARN_FOR_CLIENT>"
```

Once you apply the config, it will generate a `config.ovpn` file for connecting to VPN; make sure to edit it as per Client VPN [README](https://github.com/imyousuf/terraform-aws-webhook-broker/blob/main/modules/client-vpn/README.md).

Also set the following variables -

```terraform
webhook_broker_https_cert_arn    = "arn:aws:acm:<REGION>:<ACCOUNT_ID>:certificate/<HTTPS_CERT_FOR_HOSTNAME>"
webhook_broker_access_log_bucket = "logs-bucket"
webhook_broker_access_log_path   = "path-prefix"
webhook_broker_hostname          = "match-hostname-to-certificate"
webhook_broker_log_bucket        = "cluster-log-bucket"
webhook_broker_log_path          = "cluster/path/prefix"
map_roles = [
    {
      rolearn  = "arn:aws:iam::<ACCOUNT_NUMBER>:role/<ROLE_NAME>"
      username = "<ROLE_NAME>"
      groups   = ["system:masters"]
    }
  ]
map_users = [
    {
      userarn  = "arn:aws:iam::<ACCOUNT_NUMBER>:user/<USER_NAME>"
      username = "<USER_NAME>"
      groups   = ["system:masters"]
    }
  ]
```

The `kubernetes-dashboard` ingress controller is disabled by default as we are deploying the cluster in public subnet; please consider enabling it when deploying in a private subnet by passing [Helm Chart values](https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard).

Get login token to access the dashboard using -

```bash
export KUBECONFIG=kubeconfig_test-eks-w7b6
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep k8s-dashboard-svc-controller-token | awk '{print $1}')
```

## Modules

In creating the stack we made several parts reusable individually -

1. [Client VPN](https://github.com/imyousuf/terraform-aws-webhook-broker/blob/main/modules/client-vpn/README.md)
1. [EKS Cluster](https://github.com/imyousuf/terraform-aws-webhook-broker/blob/main/modules/simple-kubernetes/README.md)
1. [EKS Cluster Goodies](https://github.com/imyousuf/terraform-aws-webhook-broker/blob/main/modules/kubernetes-goodies/README.md)
1. [Webhook Broker](https://github.com/imyousuf/terraform-aws-webhook-broker/blob/main/modules/w7b6/README.md)

## Production Note

For production use - I would not recommend using the root module for managing a production environment. My recommendation would be to separate it into 3 TF workspaces -

1. VPN and Network - so that various application can be launched in it
1. Log aggregation infrastructure - Since it will be used by k8s and non-k8s services alike
1. Kubernetes Cluster and Goodies - so that multiple applications can be deployed
1. Webhook Broker(s) - if you have multiple brokers they can be managed through a single workspace.

## Known Issues

Also when destroying the entire stack, you might end up with EKS being destroyed, but erroring out on goodies in deleted; that can be deleted and just delete the `terraform.tfstate` once you have run `terraform destroy` enough time until only the helm charts are left. Please use `destroy-stack.sh` to progressively destroy of the stack without any hiccups.

One other thing to note is, when `terraform destroy` is called, it will delete the ALB and the Route53 records, but not instantly and it happens asynchronously; so please delete them manually in case the `goodies` module gets removed before they are deleted.
