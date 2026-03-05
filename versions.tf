# ------------------------------------------------------------------------------
# Terraform and Provider Version Constraints
# Ensures compatible versions of Terraform and providers
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  # ------------------------------------------------------------------------------
  # Required Providers - AWS, Kubernetes, TLS
  # ------------------------------------------------------------------------------
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}
