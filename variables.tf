# ------------------------------------------------------------------------------
# Root Module - Input Variables
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# AWS Configuration
# ------------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region for EKS cluster"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ------------------------------------------------------------------------------
# EKS Cluster Configuration
# ------------------------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster (e.g., 1.32)"
  type        = string
  default     = "1.32"
}

# ------------------------------------------------------------------------------
# VPC and Networking Configuration
# ------------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones for the region (null = auto-detect)"
  type        = list(string)
  default     = null
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cost-saving) vs one per AZ"
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Node Group Configuration
# ------------------------------------------------------------------------------
variable "node_instance_types" {
  description = "Instance types for EKS node groups (t3.micro is free tier eligible)"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "node_desired_size" {
  description = "Desired number of nodes in the default node group"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

# ------------------------------------------------------------------------------
# Access Control
# ------------------------------------------------------------------------------
variable "enable_cluster_creator_admin_permissions" {
  description = "Grant cluster creator admin access via aws-auth ConfigMap"
  type        = bool
  default     = true
}
