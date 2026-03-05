# ------------------------------------------------------------------------------
# EKS Module - Outputs
# Exposes cluster endpoint, ARN, and kubeconfig command
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Cluster Identity
# ------------------------------------------------------------------------------
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = module.eks.cluster_version
}

# ------------------------------------------------------------------------------
# Cluster Endpoint and Authentication
# ------------------------------------------------------------------------------
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster (IRSA)"
  value       = module.eks.cluster_oidc_issuer_url
}
