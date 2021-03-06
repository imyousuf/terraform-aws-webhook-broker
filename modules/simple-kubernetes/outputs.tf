output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = element(concat(module.eks.*.cluster_endpoint, list("")), 0)
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = element(concat(module.eks.*.cluster_security_group_id, list("")), 0)
}

output "kubectl_config" {
  description = "kubectl config as generated by the module."
  value       = element(concat(module.eks.*.kubeconfig, list("")), 0)
}

output "kubeconfig_filename" {
  description = "kubectl config file generated by the module."
  value       = element(concat(module.eks.*.kubeconfig_filename, list("")), 0)
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = element(concat(module.eks.*.config_map_aws_auth, list("")), 0)
}

output "cluster_id" {
  value       = module.eks.cluster_id
  description = "EKS Cluster ID"
}

output "cluster_oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "OpenID Provider URL for the EKS Cluster"
}
