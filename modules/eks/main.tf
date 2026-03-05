# ------------------------------------------------------------------------------
# EKS Module - Main Configuration
# Provisions EKS cluster, add-ons, and managed node groups
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# EKS Cluster - Control plane and core configuration
# ------------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.5"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # ------------------------------------------------------------------------------
  # Networking - VPC and subnets for the cluster
  # ------------------------------------------------------------------------------
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # ------------------------------------------------------------------------------
  # API Server Endpoints - Public and/or private access
  # ------------------------------------------------------------------------------
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  # ------------------------------------------------------------------------------
  # Cluster Creator - Grant admin access to cluster creator via aws-auth
  # ------------------------------------------------------------------------------
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  # ------------------------------------------------------------------------------
  # Add-ons - VPC CNI, CoreDNS, kube-proxy (managed by EKS)
  # ------------------------------------------------------------------------------
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # ------------------------------------------------------------------------------
  # Managed Node Groups - EC2 instances running workloads
  # ------------------------------------------------------------------------------
  eks_managed_node_groups = {
    general = {
      name = "general-nodes"

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      tags = merge(var.tags, {
        NodeGroup = "general"
      })
    }
  }
}
