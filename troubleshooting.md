# Incident Postmortem — EKS Node Group Creation Failure

**Cluster:** `dev-nest-eks-cluster`
**Region:** `us-east-2`
**Status:** ✅ Resolved
**Severity:** High — complete inability to run workloads on EKS cluster

---

## Summary

EKS node group creation repeatedly failed with a `NodeCreationFailure` error. Worker nodes were launching successfully but never registering with the Kubernetes cluster. The root cause was a restrictive EKS public endpoint access policy that blocked the NAT Gateway's outbound IP, preventing private-subnet worker nodes from reaching the EKS API server.

---

## Timeline

| Time (UTC)   | Event                                                                 |
|--------------|-----------------------------------------------------------------------|
| T+00:00      | EKS cluster `dev-nest-eks-cluster` created successfully               |
| 19:45:36     | First node group creation attempt initiated                           |
| 20:18:51     | First failure confirmed — instance `i-0ec990459d789bc61`              |
| 20:43:31     | Second node group creation attempt started                            |
| 21:53:48     | Third node group creation attempt started                             |
| 22:27:06     | Third attempt failed — instance `i-0c435889094f5b906`                 |
| Resolution   | NAT Gateway IP (`3.141.116.198/32`) added to EKS public access CIDRs |
| Final        | Node group creation succeeded; nodes registered successfully          |

---

## Root Cause

Worker nodes in private subnets route all outbound traffic through a NAT Gateway. The EKS cluster's public API endpoint had access restricted to a single IP (`102.89.85.135/32`). The NAT Gateway's public IP (`3.141.116.198`) was not included in the allowed CIDRs, so every node registration attempt was silently blocked at the API level.

Private endpoint access alone was insufficient due to DNS resolution behavior in the VPC configuration.

```
Worker Node (private subnet)
    └── Route Table → NAT Gateway (3.141.116.198)
            └── EKS API Server
                    └── ❌ Blocked — IP not in allowed CIDRs
```

---

## Investigation Steps

### 1. Subnet Tags — Checked, Not the Cause
Missing EKS-required subnet tags were found and added:

```
kubernetes.io/cluster/dev-nest-eks-cluster = shared
kubernetes.io/role/internal-elb = 1
```

Node group creation still failed after this fix.

---

### 2. IAM Role Permissions — Verified Correct
All required policies were confirmed attached to the node group role:

- ✅ `AmazonEKSWorkerNodePolicy`
- ✅ `AmazonEKS_CNI_Policy`
- ✅ `AmazonEC2ContainerRegistryReadOnly`

---

### 3. Network Infrastructure — Verified Correct
- ✅ NAT Gateway available and routing correctly
- ✅ Route tables correctly configured for private subnets
- ✅ Security groups allowing required traffic
- ✅ EC2 instances healthy with all status checks passing

---

### 4. Instance-Level Analysis — Key Discovery
Inspected failed instance `i-0c435889094f5b906` via console output:

- ✅ Instance running and healthy
- ✅ `kubelet` and `containerd` started successfully
- ✅ `cloud-init` completed without errors
- ✅ `nodeadm` configured successfully for EKS
- ❌ **0 nodes registered in the Kubernetes cluster**

The node was fully booted and configured — it simply could not reach the API server to register.

---

### 5. EKS Endpoint Access — Root Cause Confirmed
Reviewed EKS cluster networking configuration:

| Setting             | Value                    |
|---------------------|--------------------------|
| Public endpoint     | Enabled                  |
| Allowed CIDRs       | `102.89.85.135/32` only  |
| NAT Gateway public IP | `3.141.116.198`        |
| NAT Gateway IP allowed? | ❌ No                 |

---

## Resolution

**1. Identify NAT Gateway public IP**

```bash
# NAT Gateway public IP: 3.141.116.198
```

**2. Update EKS public access CIDRs**

Navigate to: `EKS Console → Cluster → Networking → Manage networking`

Added `3.141.116.198/32` alongside the existing `102.89.85.135/32`.

**3. Delete the failed node group**

Removed `dev-nest-eks-worker-node` and waited for full deletion.

**4. Re-create the node group**

Created with identical configuration. Nodes registered successfully.

---

## Affected Resources

| Resource       | ID / Value                                   |
|----------------|----------------------------------------------|
| EKS Cluster    | `dev-nest-eks-cluster`                        |
| Node Group     | `dev-nest-eks-worker-node`                    |
| Failed Instances | `i-0ec990459d789bc61`, `i-073d9a126a93113c8`, `i-0c435889094f5b906` |
| NAT Gateway    | `nat-00d3ff893c8419e35`                       |
| NAT Gateway IP | `3.141.116.198`                               |
| VPC            | `vpc-03164414756085a81`                       |
| Subnets        | `subnet-06f812660eea6de6f`, `subnet-028d56d3bb72f180a` |

---

## Key Takeaways

- **`NodeCreationFailure` is misleading.** Nodes were launching and booting fine. The error masked an API connectivity issue — not a provisioning failure.
- **Private subnets + restricted endpoint = silent failure.** Nodes cannot register without API access. When public endpoint CIDRs are locked down, the NAT Gateway IP must be explicitly included.
- **Subnet tags are required but not sufficient.** Fixing them didn't resolve the issue. Network connectivity is the critical dependency.
- **Private endpoint alone wasn't enough** due to DNS resolution behavior in this VPC setup.

---

## Prevention Checklist

### EKS Cluster Setup
- [ ] Include NAT Gateway IP(s) in public endpoint access CIDRs before creating node groups
- [ ] Enable both public and private endpoint access during initial setup
- [ ] Verify VPC DNS hostname resolution is enabled

### Node Group Pre-flight
- [ ] Confirm required subnet tags are in place
- [ ] Validate route table configuration
- [ ] Test API connectivity from within private subnets

### Monitoring
- [ ] Set up CloudWatch alarms for node group creation failures
- [ ] Monitor EKS cluster events during node group provisioning
- [ ] Track node registration metrics post-creation

---

## Useful Debugging Commands

```bash
# Check node registration status
kubectl get nodes

# Describe node group for events
aws eks describe-nodegroup \
  --cluster-name dev-nest-eks-cluster \
  --nodegroup-name dev-nest-eks-worker-node

# Pull instance system logs
aws ec2 get-console-output --instance-id <instance-id>

# Test API server reachability
curl -k https://<eks-api-endpoint>
```

---

*Next Review: Monitor node group stability over the next 7 days.*