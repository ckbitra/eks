# ------------------------------------------------------------------------------
# VPC Module - Main Configuration
# Provisions VPC, subnets, and NAT gateway for EKS
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# VPC - Creates the Virtual Private Cloud
# ------------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name}-vpc"
  cidr = var.vpc_cidr

  # ------------------------------------------------------------------------------
  # Subnets - Public and private across availability zones
  # ------------------------------------------------------------------------------
  azs             = var.azs
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # ------------------------------------------------------------------------------
  # NAT Gateway - Internet access for private subnets
  # ------------------------------------------------------------------------------
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  # ------------------------------------------------------------------------------
  # DNS - Required for EKS and private endpoints
  # ------------------------------------------------------------------------------
  enable_dns_hostnames = true
  enable_dns_support   = true

  # ------------------------------------------------------------------------------
  # EKS Subnet Tags - Required for load balancer and cluster discovery
  # ------------------------------------------------------------------------------
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}
