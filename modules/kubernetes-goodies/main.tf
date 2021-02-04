locals {
  k8s_service_account_namespace       = "kube-system"
  k8s_dashboard_service_account_name  = "k8s-dashboard-svc-controller"
  k8s_autoscaler_service_account_name = "cluster-autoscaler-aws-cluster-autoscaler-chart"
  k8s_alb_service_account_name        = "aws-load-balancer-controller"
  k8s_external_dns_account_name       = "external-dns"
  k8s_fluentbit_account_name          = "aws-fluent-bit"
  k8s_dashboard_namespace             = "kubernetes-dashboard"
  k8s_metrics_namespace               = "metrics"
}

# Cluster Auto Scaler

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${var.cluster_id}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "cluster-autoscaler"
  provider_url                  = replace(var.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_autoscaler_service_account_name}"]
}

# The following configuration are to represent - https://raw.githubusercontent.com/hashicorp/learn-terraform-provision-eks-cluster/master/kubernetes-dashboard-admin.rbac.yaml
# From - https://learn.hashicorp.com/tutorials/terraform/eks
resource "kubernetes_cluster_role_binding" "cluster-admin-binding" {
  metadata {
    name = "cluster-admin-bindings"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.k8s_dashboard_service_account_name
    namespace = local.k8s_dashboard_namespace
  }
}

resource "helm_release" "aws-spot-termination-handler" {
  name      = "aws-node-termination-handler"
  namespace = local.k8s_service_account_namespace

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-node-termination-handler"
}

resource "helm_release" "cluster-autoscaler" {
  name      = "cluster-autoscaler"
  namespace = local.k8s_service_account_namespace

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler-chart"

  depends_on = [module.iam_assumable_role_admin]

  values = [
    templatefile("${path.module}/conf/cluster-autoscaler-chart-values.yml", { role_arn = module.iam_assumable_role_admin.this_iam_role_arn, cluster_name = var.cluster_name })
  ]
}

# Metrics Server required for HPA

# TODO: This chart has been deprecated, we will need to move to the new chart once official
# https://github.com/kubernetes-sigs/metrics-server/issues/572
resource "helm_release" "metrics_server" {
  name      = "metrics-server"
  namespace = local.k8s_service_account_namespace

  repository = "https://charts.helm.sh/stable"
  chart      = "metrics-server"
  version    = "2.11.4"

  set {
    name  = "image.repository"
    value = "k8s.gcr.io/metrics-server/metrics-server"
  }

  set {
    name  = "image.tag"
    value = "v0.4.1"
  }
}

# AWS ALB Ingression Controller

# This file is from - view-source:https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
# Following the documentation in https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller
resource "aws_iam_policy" "alb_ingress_controller" {
  name_prefix = "alb-ingress"
  description = "EKS ALB Ingress policy for cluster ${var.cluster_id}"
  policy      = file("${path.module}/conf/aws-alb-ingress-policy.json")
}

module "iam_assumable_role_ingress" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "alb-ingress"
  provider_url                  = replace(var.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.alb_ingress_controller.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_alb_service_account_name}"]
}

resource "helm_release" "alb_ingress_controller" {
  name      = "aws-load-balancer-controller"
  namespace = local.k8s_service_account_namespace

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  depends_on = [module.iam_assumable_role_ingress]

  values = [templatefile("${path.module}/conf/alb-ingress-chart-values.yml", { role_arn = module.iam_assumable_role_ingress.this_iam_role_arn, svc_acc_name = local.k8s_alb_service_account_name, cluster_name = var.cluster_name, region = var.region, vpc_id = var.vpc_id })]
}

# External DNS

resource "aws_iam_policy" "external_dns" {
  name_prefix = "external-dns"
  description = "External DNS policy for cluster ${var.cluster_id}"
  policy      = file("${path.module}/conf/external-dns-policy.json")
}

module "iam_assumable_role_external_dns" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "external-dns"
  provider_url                  = replace(var.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_external_dns_account_name}"]
}

resource "helm_release" "external_dns" {
  name      = "external-dns"
  namespace = local.k8s_service_account_namespace

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"

  depends_on = [module.iam_assumable_role_external_dns]

  values = [templatefile("${path.module}/conf/external-dns-chart-values.yml", { role_arn = module.iam_assumable_role_external_dns.this_iam_role_arn, svc_acc_name = local.k8s_external_dns_account_name, region = var.region, policy = var.external_dns_r53_sync ? "sync" : "upsert-only" })]
}

# Kubernetes Dashboard

resource "kubernetes_namespace" "k8s-dashboard-namespace" {
  metadata {
    name = local.k8s_dashboard_namespace
  }
}

resource "helm_release" "kubernetes-dashboard" {
  name      = "kubernetes-dashboard"
  namespace = local.k8s_dashboard_namespace

  repository = "https://kubernetes.github.io/dashboard/"
  chart      = "kubernetes-dashboard"
  depends_on = [kubernetes_namespace.k8s-dashboard-namespace, helm_release.external_dns, helm_release.alb_ingress_controller, helm_release.metrics_server]

  set {
    name  = "serviceAccount.name"
    value = local.k8s_dashboard_service_account_name
  }
  set {
    name  = "ingress.enabled"
    value = true
  }
  set {
    name  = "metricsScraper.enabled"
    value = true
  }
  values = var.k8s_dashboard_chart_values
}

# Fluent bit

resource "aws_iam_policy" "fluent_bit" {
  name_prefix = "fluent-bit"
  description = "Fluent Bit policy for cluster ${var.cluster_id}"
  policy      = file("${path.module}/conf/fluent-bit-policy.json")
}

module "iam_assumable_role_fluent_bit" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "fluent-bit"
  provider_url                  = replace(var.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.fluent_bit.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_fluentbit_account_name}"]
}

resource "helm_release" "aws_fluent_bit" {
  name      = "aws-for-fluent-bit"
  namespace = local.k8s_service_account_namespace

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"

  depends_on = [module.iam_assumable_role_fluent_bit]

  values = [templatefile("${path.module}/conf/fluent-bit-chart-values.yml", { connect_es = var.connect_es, role_arn = module.iam_assumable_role_fluent_bit.this_iam_role_arn, svc_acc_name = local.k8s_fluentbit_account_name, region = var.region, es_url = var.es_url, log_s3_bucket = var.log_s3_bucket, log_s3_path_prefix = var.log_s3_path_prefix, additional_fluentbit_output = var.additional_fluentbit_output })]
}
