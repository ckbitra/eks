# Amazon EKS - Components & Shared Responsibility

## Overview

Amazon Elastic Kubernetes Service (EKS) is a managed Kubernetes service that makes it easier to run Kubernetes on AWS. Understanding its components and the shared responsibility model is essential for DevOps Engineers.

---

## 1. EKS Architecture Components

### Control Plane (Managed by AWS)

| Component | Description |
|-----------|-------------|
| **API Server** | Entry point for all cluster operations; validates and processes REST requests |
| **etcd** | Distributed key-value store for cluster state; highly available across multiple AZs |
| **Scheduler** | Assigns pods to nodes based on resource requirements and constraints |
| **Controller Manager** | Runs controller processes (Node, Replication, Endpoints, Service Account, etc.) |
| **Cloud Controller Manager** | Integrates with AWS services (ELB, EBS, Route53, etc.) |

### Data Plane / Worker Nodes (Customer Managed)

| Component | Description |
|-----------|-------------|
| **kubelet** | Agent that runs on each node; ensures containers are running in a pod |
| **kube-proxy** | Network proxy maintaining network rules for pods (Service abstraction) |
| **Container Runtime** | containerd (default) or CRI-O for running containers |
| **EKS Optimized AMI** | Pre-configured AMI with kubelet, containerd, and AWS integrations |

### Networking Components

| Component | Description | Managed By |
|-----------|-------------|------------|
| **VPC CNI** | AWS VPC CNI plugin for pod networking; assigns VPC IPs to pods | Customer (add-on) |
| **CoreDNS** | Cluster DNS for service discovery | Customer (add-on) |
| **kube-proxy** | Handles Service networking (ClusterIP, NodePort, LoadBalancer) | Customer |

### Add-ons (Configurable)

- **VPC CNI** – Pod networking
- **CoreDNS** – Cluster DNS
- **kube-proxy** – Service proxy
- **EBS CSI Driver** – EBS volume provisioning
- **EFS CSI Driver** – EFS volume provisioning
- **AWS Load Balancer Controller** – ALB/NLB ingress
- **Metrics Server** – Resource metrics for HPA/VPA

---

## 2. Shared Responsibility Model

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    AMAZON EKS SHARED RESPONSIBILITY                               │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  ┌──────────────────────────────┐    ┌──────────────────────────────┐           │
│  │   MANAGED BY AWS             │    │   MANAGED BY CUSTOMER        │           │
│  ├──────────────────────────────┤    ├──────────────────────────────┤           │
│  │                              │    │                              │           │
│  │ • Control Plane (API Server) │    │ • Worker Nodes (EC2/Fargate) │           │
│  │ • etcd (multi-AZ, HA)        │    │ • Node provisioning & scaling│           │
│  │ • Scheduler                  │    │ • VPC, Subnets, Security     │           │
│  │ • Controller Manager         │    │   Groups, NACLs              │           │
│  │ • Cloud Controller Manager   │    │ • IAM Roles & Policies       │           │
│  │ • Control plane security     │    │ • Add-on configuration       │           │
│  │   & patches                  │    │ • Pod Security Policies      │           │
│  │ • Control plane availability │    │ • Network policies           │           │
│  │ • EKS API & Console          │    │ • Application deployment     │           │
│  │                              │    │ • Secrets management         │           │
│  │                              │    │ • Logging (CloudWatch)       │           │
│  │                              │    │ • Backup & DR for apps       │           │
│  └──────────────────────────────┘    └──────────────────────────────┘           │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### AWS Responsibilities (Summary)

- Provisioning, scaling, and securing the Kubernetes control plane
- High availability of the control plane across multiple AZs
- Patching and updating control plane components
- etcd backups and durability
- Compliance certifications (SOC, PCI-DSS, HIPAA, etc.) for the control plane

### Customer Responsibilities (Summary)

- Provisioning and managing worker nodes (or using Fargate)
- Configuring VPC, subnets, and network security
- Managing IAM roles for the cluster and service accounts (IRSA)
- Installing and configuring add-ons
- Securing workloads (RBAC, Network Policies, Pod Security)
- Application deployment, scaling, and monitoring
- Logging, auditing, and compliance for workloads

---

## 3. Pictorial Architecture Diagram

```
                                    ┌─────────────────────────────────────────────────────────┐
                                    │                  AMAZON EKS CLUSTER                      │
                                    └─────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────────────────────────────────────────┐
    │                        CONTROL PLANE (AWS Managed - Multi-AZ)                                 │
    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
    │  │ API Server  │  │   etcd      │  │  Scheduler  │  │  Controller │  │ Cloud Controller    │ │
    │  │             │  │  (Cluster   │  │             │  │   Manager   │  │ Manager (AWS Integ) │ │
    │  │ Entry Point │  │   State)    │  │ Pod→Node    │  │             │  │ ELB, EBS, Route53   │ │
    │  └──────┬──────┘  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────────┘ │
    └─────────┼───────────────────────────────────────────────────────────────────────────────────┘
              │
              │ kubectl / API calls
              │
    ┌─────────▼───────────────────────────────────────────────────────────────────────────────────┐
    │                        DATA PLANE (Customer Managed)                                         │
    │                                                                                             │
    │  ┌─────────────────────────┐  ┌─────────────────────────┐  ┌─────────────────────────┐     │
    │  │    Worker Node 1        │  │    Worker Node 2        │  │    Worker Node N        │     │
    │  │  ┌─────────────────┐   │  │  ┌─────────────────┐   │  │  ┌─────────────────┐   │     │
    │  │  │ kubelet         │   │  │  │ kubelet         │   │  │  │ kubelet         │   │     │
    │  │  │ kube-proxy      │   │  │  │ kube-proxy      │   │  │  │ kube-proxy      │   │     │
    │  │  │ containerd      │   │  │  │ containerd      │   │  │  │ containerd      │   │     │
    │  │  │ VPC CNI         │   │  │  │ VPC CNI         │   │  │  │ VPC CNI         │   │     │
    │  │  └────────┬────────┘   │  │  └────────┬────────┘   │  │  └────────┬────────┘   │     │
    │  │           │ Pods       │  │           │ Pods       │  │           │ Pods       │     │
    │  └───────────┼────────────┘  └───────────┼────────────┘  └───────────┼────────────┘     │
    │              │                           │                           │                   │
    └──────────────┼───────────────────────────┼───────────────────────────┼───────────────────┘
                   │                           │                           │
    ┌──────────────▼───────────────────────────▼───────────────────────────▼───────────────────┐
    │                           VPC (Customer Managed)                                          │
    │  • Public/Private Subnets  • Security Groups  • NAT Gateway  • VPC CNI (Pod Networking)   │
    └──────────────────────────────────────────────────────────────────────────────────────────┘
                   │                           │                           │
    ┌──────────────▼───────────────────────────▼───────────────────────────▼───────────────────┐
    │                        AWS SERVICES (Integration)                                         │
    │  ELB │ EBS │ EFS │ IAM │ CloudWatch │ Secrets Manager │ ECR │ Route 53                    │
    └──────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. DevOps Engineer - Key Considerations

### Security

- **IRSA (IAM Roles for Service Accounts)** – Prefer IRSA over `eks.amazonaws.com/role-arn` annotations for least-privilege AWS access.
- **Pod Security Standards** – Use built-in `restricted`, `baseline`, or `privileged` admission modes (Kubernetes 1.25+).
- **Network Policies** – Define allow/deny rules for pod-to-pod traffic.
- **Security Groups** – Use the EKS-managed security group for the control plane; manage node and pod security groups separately.
- **Secrets** – Use AWS Secrets Manager / Parameter Store with External Secrets Operator or CSI driver instead of plain Kubernetes Secrets for sensitive data.

### Networking

- **VPC CNI** – Consider custom networking (subnets dedicated to pods) and prefix delegation for large clusters.
- **IP exhaustion** – Plan subnet sizing; each pod gets an IP from the VPC.
- **Load balancing** – Use AWS Load Balancer Controller for ALB/NLB Ingress and proper target group management.
- **Private cluster** – Use private endpoint + public access restricted to your CIDR for production.

### Scalability & Performance

- **Node groups** – Use managed node groups for simpler operations; consider multiple node groups for different instance types/GPU.
- **Cluster Autoscaler** – Configure correctly for EKS (correct tags and discovery).
- **Karpenter** – Evaluate Karpenter as an alternative to Cluster Autoscaler for faster, more flexible scaling.
- **Fargate** – Use for serverless workloads; note cold start and per-pod billing.

### Observability

- **Control plane logging** – Enable API, audit, authenticator, scheduler, and controller manager logs to CloudWatch.
- **Container Insights** – Enable for metrics and logs.
- **Prometheus + Grafana** – Common choice; consider Amazon Managed Prometheus and Managed Grafana.
- **Fluent Bit / Fluentd** – Use for log shipping to CloudWatch or other sinks.

### Operations

- **Version upgrades** – Control plane upgrades are managed by AWS; plan node upgrades (canary or rolling) and test add-ons.
- **Backup** – Use Velero for workload backup and disaster recovery.
- **GitOps** – Use Argo CD or Flux for declarative GitOps workflows.
- **Cost** – Monitor control plane cost (~$0.10/hr per cluster) and optimize node usage (Spot, Fargate Spot, rightsizing).

### Compliance & Governance

- **EKS Access Entry** – Configure IAM principal access (post-Nov 2024) for cluster access.
- **AWS Config** – Enable EKS recording rules for compliance.
- **GuardDuty** – Enable for threat detection; use EKS Protection for runtime security.

---

## 5. Quick Reference

| Aspect | AWS Manages | Customer Manages |
|--------|-------------|------------------|
| **Control Plane** | ✅ API, etcd, Scheduler, Controllers | — |
| **Worker Nodes** | — | ✅ EC2 / Fargate |
| **Networking** | — | ✅ VPC, CNI config, CoreDNS |
| **Add-ons** | — | ✅ Install, configure, upgrade |
| **IAM** | — | ✅ Cluster role, node role, IRSA |
| **Applications** | — | ✅ Deployments, Services, ConfigMaps, etc. |
| **Logging** | — | ✅ Enable & configure |

---

*Document created for DevOps Engineers working with Amazon EKS. Keep this as a reference for architecture discussions and operational planning.*
