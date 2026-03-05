# EKS Upgrade Guide: 1.32 → 1.33

This document outlines the steps to upgrade an Amazon EKS cluster from Kubernetes 1.32 to 1.33 when managed with Terraform, including backup considerations.

---

## Pre-Upgrade Checklist

### 1. Backup Considerations

| Backup Type | How | When |
|-------------|-----|------|
| **Terraform state** | Copy state file or use versioned S3 backend | Before any changes |
| **EKS cluster** | AWS Backup (if configured) or manual snapshot | Optional but recommended |
| **ETCD** | Managed by AWS (no direct backup) | N/A |
| **Application data** | PVC snapshots, database backups | Per application |
| **Manifests** | `kubectl get all -A -o yaml > backup.yaml` | Optional |
| **aws-auth ConfigMap** | `kubectl get configmap aws-auth -n kube-system -o yaml` | Recommended |

### 2. Backup Commands (Run Before Upgrade)

```bash
# 1. Terraform state backup (if using local state)
terraform state pull > terraform.state.backup.$(date +%Y%m%d)

# 2. Export cluster manifests (optional)
kubectl get all -A -o yaml > cluster-backup-$(date +%Y%m%d).yaml

# 3. Save aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-backup.yaml

# 4. List all PVCs (for manual backup decisions)
kubectl get pvc -A

# 5. Document current add-on versions
kubectl get daemonset -n kube-system
kubectl get deployment -n kube-system
```

### 3. Enable AWS Backup (Optional, Recommended for Production)

If not already configured:

```hcl
# Add to Terraform or create separately
resource "aws_backup_vault" "eks" {
  name = "eks-backup-vault"
}

resource "aws_backup_plan" "eks" {
  name = "eks-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.eks.name
    schedule          = "cron(0 5 ? * * *)"  # Daily at 5 AM UTC

    lifecycle {
      delete_after = 7
    }
  }
}
```

---

## Upgrade Steps

### Step 1: Review EKS Upgrade Insights

**Before making changes**, use AWS Console or CLI to check upgrade readiness:

```bash
# Via AWS CLI
aws eks describe-cluster --name <cluster-name> --region <region>
```

In **AWS Console**: EKS → Clusters → [your cluster] → **Insights** tab
- Check for deprecated API usage
- Address any blocking issues (deprecated resources, incompatible add-ons)

### Step 2: Update Node Groups First (If on AL2)

**EKS 1.33 requires Amazon Linux 2023 (AL2023).** If your node groups use AL2:

- Create a new node group with `ami_type = "AL2023_x86_64_STANDARD"`
- Cordon and drain old nodes
- Scale down/remove old AL2 node group
- Then proceed with control plane upgrade

**This Terraform config already uses AL2023**, so you can skip this step.

### Step 3: Update Terraform Configuration

**File: `variables.tf` or `terraform.tfvars`**

```hcl
# Change from:
cluster_version = "1.32"

# To:
cluster_version = "1.33"
```

**File: `eks.tf`** (if cluster_version is hardcoded)

```hcl
cluster_version = "1.33"
```

### Step 4: Plan and Review

```bash
terraform plan -out=upgrade.tfplan
```

Review the plan. Expected changes:
- `cluster_version` update on `aws_eks_cluster`
- Possible add-on version updates (vpc-cni, coredns, kube-proxy)

### Step 5: Apply the Upgrade

```bash
terraform apply upgrade.tfplan
```

**Note:** The control plane upgrade typically takes **10–20 minutes**. It cannot be paused or reverted.

### Step 6: Monitor the Upgrade

```bash
# Watch cluster status
aws eks describe-update --name <cluster-name> --update-id <update-id> --region <region>

# Or in Console: EKS → Clusters → [cluster] → Updates tab
```

### Step 7: Update Node Groups (if needed)

Managed node groups may need to be updated to the new AMI/version. The EKS module typically handles this. If nodes remain on an older kubelet:

```bash
# Check node versions
kubectl get nodes -o wide

# Node groups may auto-update; if not, trigger via Terraform
terraform apply
```

### Step 8: Update Add-ons

Ensure add-ons are compatible with 1.33:

| Add-on | Action |
|--------|--------|
| vpc-cni | Use 1.16.2+ (required for AL2023) |
| CoreDNS | Use recommended version for 1.33 |
| kube-proxy | Use recommended version for 1.33 |

The EKS module with `most_recent = true` should pull compatible versions. Verify in Console: EKS → Add-ons.

### Step 9: Update Cluster Autoscaler (if used)

If you run Cluster Autoscaler:

```bash
kubectl set image deployment/cluster-autoscaler \
  cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:v1.33.x \
  -n kube-system
```

Replace `v1.33.x` with the latest 1.33.x release.

### Step 10: Update kubectl

Use a kubectl version within one minor of the cluster (e.g., 1.32, 1.33, or 1.34 for cluster 1.33):

```bash
kubectl version --client
```

---

## Post-Upgrade Verification

```bash
# Cluster version
kubectl version

# Node status
kubectl get nodes

# System pods
kubectl get pods -n kube-system

# Add-on status (Console: EKS → Add-ons)
# Ensure all show "Active"
```

---

## Rollback

**EKS does not support downgrading** the control plane. If the upgrade fails:

1. AWS may revert the control plane automatically in some failure scenarios
2. If the cluster is unhealthy: open an AWS Support case
3. Restore from backup: create a new cluster from Terraform state backup and migrate workloads

**Prevention:** Test the upgrade in a non-production cluster first.

---

## Known Considerations for 1.33

| Item | Notes |
|------|-------|
| **AL2 deprecation** | EKS 1.33 supports only AL2023; this config already uses AL2023 |
| **Anonymous auth** | More restricted; ensure RBAC is correct |
| **Karpenter** | v1.0+ needs `eks:DescribeCluster` IAM permission |
| **Add-on deadlock** | If add-ons get stuck "Updating", resolve node NotReady issues first |

---

## Timeline Summary

| Phase | Duration |
|-------|----------|
| Backup | 5–10 min |
| Terraform plan/apply | 15–25 min |
| Node group refresh | 5–15 min |
| Add-on updates | 5–10 min |
| **Total** | ~30–60 min |

---

## Quick Reference

```bash
# 1. Backup
terraform state pull > state.backup

# 2. Update cluster_version to "1.33" in Terraform

# 3. Apply
terraform plan -out=upgrade.tfplan
terraform apply upgrade.tfplan

# 4. Verify
kubectl get nodes
kubectl get pods -A
```
