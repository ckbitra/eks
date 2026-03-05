# Terraform Modularity Diagram and Workflow

## Module Structure

```
EKS_Upgrade/
├── main.tf                    # Root: provider, data, locals, module calls
├── variables.tf               # Root: input variables
├── outputs.tf                 # Root: cluster outputs
├── versions.tf                # Terraform and provider constraints
├── terraform.tfvars.example   # Example variable values
│
└── modules/
    ├── vpc/                   # Network module
    │   ├── main.tf            # Calls terraform-aws-modules/vpc
    │   ├── variables.tf       # VPC input variables
    │   └── outputs.tf         # vpc_id, private_subnets, public_subnets
    │
    └── eks/                   # EKS cluster module
        ├── main.tf            # Calls terraform-aws-modules/eks
        ├── variables.tf       # EKS input variables
        └── outputs.tf         # cluster_endpoint, cluster_arn, etc.
```

## Modularity Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              ROOT MODULE                                         │
│                                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │ versions.tf  │    │ variables.tf │    │   main.tf    │    │  outputs.tf  │   │
│  │              │    │              │    │              │    │              │   │
│  │ • Providers  │    │ • cluster_   │    │ • Provider   │    │ • cluster_   │   │
│  │ • Terraform  │    │   name       │    │ • Data       │    │   endpoint   │   │
│  │   version    │    │ • region     │    │ • Locals     │    │ • configure_ │   │
│  │              │    │ • vpc_cidr   │    │ • module.vpc │    │   kubectl    │   │
│  └──────────────┘    │ • node_*     │    │ • module.eks │    └──────────────┘   │
│                      └──────┬───────┘    └──────┬───────┘                       │
│                             │                   │                               │
└─────────────────────────────┼───────────────────┼───────────────────────────────┘
                              │                   │
              ┌───────────────┴───────────────────┴───────────────┐
              │                                                   │
              ▼                                                   ▼
┌─────────────────────────────┐                   ┌─────────────────────────────┐
│      MODULE: VPC            │                   │      MODULE: EKS            │
│      ./modules/vpc          │                   │      ./modules/eks          │
│                             │                   │                             │
│  Inputs:                    │   vpc_id          │  Inputs:                    │
│  • name, vpc_cidr           │   subnet_ids ────►│  • cluster_name, version    │
│  • azs, subnet CIDRs        │                   │  • vpc_id, subnet_ids       │
│  • nat_gateway settings     │                   │  • node_instance_types      │
│  • cluster_name (tags)      │                   │  • node scaling config      │
│                             │                   │                             │
│  Uses: terraform-aws-       │                   │  Uses: terraform-aws-       │
│  modules/vpc/aws            │                   │  modules/eks/aws            │
│                             │                   │                             │
│  Outputs:                   │                   │  Outputs:                   │
│  • vpc_id                   │                   │  • cluster_endpoint         │
│  • private_subnets          │                   │  • cluster_arn              │
│  • public_subnets           │                   │  • cluster_version          │
└─────────────────────────────┘                   └─────────────────────────────┘
```

## Data Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  terraform.tfvars│     │  data sources   │     │     locals      │
│                 │     │                 │     │                 │
│ cluster_name    │     │ aws_region      │     │ azs = coalesce( │
│ aws_region      │     │ aws_availability│     │   var.azs,      │
│ cluster_version │     │ _zones          │     │   data.azs)     │
│ node_*          │     │                 │     │                 │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │      module "vpc"      │
                    │  name, vpc_cidr, azs   │
                    │  private_subnet_cidrs  │
                    │  cluster_name          │
                    └────────────┬───────────┘
                                 │
                                 │  vpc_id, private_subnets
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │      module "eks"      │
                    │  cluster_name, version │
                    │  vpc_id, subnet_ids ◄──┤
                    │  node_*                │
                    └────────────┬───────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │       outputs.tf       │
                    │  cluster_endpoint      │
                    │  configure_kubectl     │
                    └────────────────────────┘
```

## Workflow Explanation

### 1. Initialization (`terraform init`)

- Loads the AWS, Kubernetes, and TLS providers from the registry
- Initializes the local `vpc` and `eks` modules
- Each module pulls its own upstream dependency:
  - **vpc** → `terraform-aws-modules/vpc/aws` (~> 5.0)
  - **eks** → `terraform-aws-modules/eks/aws` (~> 20.5)

### 2. Planning (`terraform plan`)

- Reads variables from `terraform.tfvars` and CLI
- Evaluates data sources (region, AZs)
- Computes locals (e.g. `azs`)
- Builds the dependency graph: VPC must exist before EKS (EKS needs `vpc_id` and `subnet_ids`)
- Compares desired state to current state and shows changes

### 3. Apply (`terraform apply`)

Resources are created in dependency order:

1. **Data sources** – Region, AZs
2. **VPC module** – VPC, subnets, NAT gateway, route tables, EKS subnet tags
3. **EKS module** – Uses VPC outputs:
   - IAM roles
   - EKS control plane (v1.32)
   - Add-ons (VPC CNI, CoreDNS, kube-proxy)
   - Managed node group (t3.micro, AL2023)
4. **aws-auth ConfigMap** – Cluster creator admin access

### 4. Outputs

- Root `outputs.tf` exposes EKS outputs (endpoint, ARN, version)
- `configure_kubectl` provides the AWS CLI command to update kubeconfig

### 5. Destroy (`terraform destroy`)

- Removes resources in reverse order: EKS (including node groups) first, then VPC
- EKS and associated resources can take 10–15 minutes to delete

## Benefits of This Structure

| Benefit | Description |
|--------|-------------|
| **Separation of concerns** | VPC and EKS are in separate modules with clear responsibilities |
| **Reusability** | Modules can be reused in other projects |
| **Testability** | Modules can be unit-tested in isolation |
| **Dependency clarity** | Root module shows VPC → EKS dependency explicitly |
| **Encapsulation** | Module internals (community modules) are hidden behind inputs/outputs |
