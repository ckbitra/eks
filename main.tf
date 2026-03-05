# ------------------------------------------------------------------------------
# Root Module - Main Configuration
# Orchestrates VPC and EKS modules to provision a complete EKS cluster
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# AWS Provider - Region and default tags
# ------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "eks-upgrade"
      ManagedBy   = "terraform"
    }
  }
}

# ------------------------------------------------------------------------------
# Data Sources - AWS account and availability zones
# ------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------------------------------------------------------------------
# Locals - Derived values
# ------------------------------------------------------------------------------
locals {
  azs = coalesce(var.azs, data.aws_availability_zones.available.names)
}

# ------------------------------------------------------------------------------
# VPC Module - Network foundation for EKS
# ------------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  name     = var.cluster_name
  vpc_cidr = var.vpc_cidr
  azs      = local.azs

  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  cluster_name = var.cluster_name
}

# ------------------------------------------------------------------------------
# EKS Module - Cluster, add-ons, and node groups
# ------------------------------------------------------------------------------
module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}
