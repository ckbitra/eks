# Terraform Workflow Diagram

## Execution Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          terraform init                                      │
│  • Download providers (aws, kubernetes, tls)                                 │
│  • Initialize modules (vpc, eks) and their dependencies                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          terraform validate                                  │
│  • Validate configuration syntax and consistency                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          terraform plan                                      │
│  • Build dependency graph (vpc → eks)                                        │
│  • Compare desired state vs current state                                    │
│  • Show create/update/destroy actions                                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          terraform apply                                     │
│  • Create resources in dependency order                                      │
│  • VPC first, then EKS (EKS depends on VPC outputs)                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          terraform output                                    │
│  • Output cluster endpoint, kubeconfig command, ARN                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

## terraform apply Resource Creation Sequence

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  PHASE 1: Data & Locals                                                       │
│  data.aws_caller_identity, data.aws_region, data.aws_availability_zones       │
│  local.azs                                                                    │
└──────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  PHASE 2: VPC Module                                                          │
│  ├── VPC (10.0.0.0/16)                                                        │
│  ├── Internet Gateway                                                         │
│  ├── Public Subnets (10.0.101-103.0/24)                                       │
│  ├── Private Subnets (10.0.1-3.0/24)                                          │
│  ├── NAT Gateway                                                              │
│  ├── Route Tables                                                             │
│  └── Subnet Tags (kubernetes.io/role/elb, cluster discovery)                  │
└──────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  PHASE 3: EKS Module                                                          │
│  ├── IAM Role (cluster)                                                       │
│  ├── EKS Cluster (control plane v1.32)                                        │
│  ├── Security Groups                                                          │
│  ├── OIDC Provider                                                            │
│  ├── Add-ons: vpc-cni, coredns, kube-proxy                                    │
│  ├── IAM Role (node group)                                                    │
│  ├── Launch Template                                                          │
│  └── EKS Managed Node Group (t3.micro, AL2023)                                │
└──────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  PHASE 4: aws-auth ConfigMap                                                  │
│  • Grants cluster creator admin access                                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Dependency Graph

```
                    ┌─────────────────────┐
                    │   variables.tf      │
                    │   terraform.tfvars  │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │      main.tf        │
                    │  (Root)             │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                │                ▼
     ┌──────────────┐          │         ┌──────────────┐
     │ module.vpc   │          │         │ module.eks   │
     │              │          │         │              │
     │ vpc_id       │──────────┘         │ vpc_id       │
     │ subnets      │───────────────────►│ subnet_ids   │
     └──────────────┘                    └──────────────┘
              │                                   │
              │                                   │
              ▼                                   ▼
     ┌──────────────┐                    ┌──────────────┐
     │ terraform-   │                    │ terraform-   │
     │ aws-modules/ │                    │ aws-modules/ │
     │ vpc/aws      │                    │ eks/aws      │
     └──────────────┘                    └──────────────┘
```
