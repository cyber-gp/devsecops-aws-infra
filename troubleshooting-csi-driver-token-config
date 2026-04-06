# Incident Note — Secrets Store CSI Driver Token Configuration

**Cluster:** `dev-nest-eks-cluster`
**Namespace:** `dev-nest-eks-namespace`
**Status:** ✅ Resolved

---

## What Was the Issue

The `CSIDriver` object for `secrets-store.csi.k8s.io` was installed without the `tokenRequests` field in its spec. This field is required for the driver to request a signed JWT token from the Kubernetes API on behalf of the pod's service account.

```yaml
# What was present — incomplete spec
spec:
  attachRequired: false
  podInfoOnMount: true
  requiresRepublish: false
  # tokenRequests was missing entirely
```

---

## Why It Caused an Issue

The Secrets Store CSI Driver relies on IRSA (IAM Roles for Service Accounts) to authenticate to AWS Secrets Manager. The flow works like this:

```
Pod (Service Account)
 └── CSI Driver requests JWT token from Kubernetes API   ← this step was broken
        └── JWT presented to AWS STS via OIDC
               └── STS returns temporary credentials
                      └── AWS Secrets Manager access granted
```

Without `tokenRequests` configured, the CSI Driver never requested the JWT token. With no token to present to AWS STS, authentication failed before it even reached Secrets Manager — causing the pod to hang indefinitely in `ContainerCreating` with this error:

```
CSI token error: serviceAccount.tokens not provided
- ensure tokenRequests is configured in CSIDriver spec
```

---

## How It Was Fixed

Patched the `CSIDriver` object to include `tokenRequests` with the AWS STS audience:

```bash
kubectl patch csidriver secrets-store.csi.k8s.io --type=merge -p '{
  "spec": {
    "tokenRequests": [
      {
        "audience": "sts.amazonaws.com"
      }
    ],
    "requiresRepublish": true
  }
}'
```

Deleted the stuck pod to force a fresh mount attempt. The deployment controller recreated it, the token was requested successfully, and the secret mounted cleanly.

---

## How to Avoid It in the Future

Since the CSI Driver is Helm-managed, always pass `tokenRequests` at install time rather than patching after the fact. A raw `helm install` without these values will always produce a broken configuration for IRSA-based secret mounting.

**Correct install command:**

```bash
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system \
  --set tokenRequests[0].audience="sts.amazonaws.com" \
  --set requiresRepublish=true
```

This also ensures the config survives future `helm upgrade` runs — a manual patch would be overwritten on the next upgrade.