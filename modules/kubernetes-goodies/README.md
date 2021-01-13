# Kubernetes Goodies

This module installs some key services and sidecars to an EKS Cluster. Most key thing to keep in mind is, `enable_irsa` must be true for the EKS cluster we want to run this module against. This module installs the following services via Helm Chart -

1. AWS Instance Termination Handler - [here](https://github.com/aws/eks-charts/tree/master/stable/aws-node-termination-handler)
1. Cluster Autoscaler to scale cluster dynamically - [here](https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html) and here
1. Kubernetes Dashboard with Metrics Scrapper - [here](https://learn.hashicorp.com/tutorials/terraform/eks) and [here](https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard)
1. `metrics-server` to make Horizontal Pod Autoscaling (HPA) to work - [here](https://github.com/helm/charts/tree/master/stable/metrics-server), this Chart is deprecated, need to move once official Chart is [released](https://github.com/kubernetes-sigs/metrics-server/issues/572).
1. `external-dns` for assigning Route53 DNS to Ingress services. - [here](https://github.com/bitnami/charts/tree/master/bitnami/external-dns)
1. AWS ALB Ingress Controller - [here](https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller)
1. AWS for Fluent Bit - [here](https://github.com/aws/eks-charts/tree/master/stable/aws-for-fluent-bit)

Some useful tips to configure the module -

1. EKS optimized [AMI IDs](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html)
1. How to [pass](https://github.com/aws/eks-charts/blob/c145468cc45719ce85d45a60c29fd48fcccff394/stable/aws-for-fluent-bit/values.yaml#L107) `additional_fluentbit_output`
1. If `connect_es` is true, must pass `es_url` for configuration to work
1. If you desire to use logstash format or ES Pipeline then `connect_es` should be `false` and choose to pass additional output as suggested in the [documentation](https://docs.fluentbit.io/manual/pipeline/outputs/elasticsearch).

Almost all of them uses IRSA. One important point to note is, when using `external-dns` and ALB Ingress; `terraform destroy` won't clean up the DNS resource by default.
