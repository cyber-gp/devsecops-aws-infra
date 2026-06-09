# Vuln-Bank AWS deployment setup

Deploy the intentionally vulnerable [devsecops-vuln-bank](https://github.com/cyber-gp/devsecops-vuln-bank) app on AWS using Terraform Cloud, EC2, Docker Compose, and GitHub Actions OIDC.

## Architecture summary

- **Terraform Cloud** provisions VPC, NAT, ALB, ACM, Route 53 zone, EC2, Secrets Manager, GitHub OIDC role.
- **EC2** (private subnet) clones the app repo and runs `docker compose`.
- **EBS** data volume (`/dev/sdf` → `/data`) persists Postgres and uploads.
- **GitHub Actions** (`vuln-bank-deploy.yml`) redeploys via SSM without SSH keys.

## Prerequisites

- AWS account with permissions to create IAM, VPC, EC2, ELB, ACM, Route 53, Secrets Manager.
- [Terraform Cloud](https://app.terraform.io) organization.
- GitHub repo `aws-demo-projects` with Actions enabled.
- A **domain name** you can register and delegate to Route 53 (Terraform creates the hosted zone).

## 1. Terraform Cloud

### Workspace

1. Create workspace **`vuln-bank-ec2`** (CLI-driven or VCS).
2. Edit [`terraform/vuln-bank/versions.tf`](../terraform/vuln-bank/versions.tf): set `organization = "YOUR_TFC_ORG"`.
3. Connect VCS to this repository with working directory **`terraform/vuln-bank`** (optional auto-apply on merge).

### Variables

In the workspace, set **Terraform variables** (from `terraform.tfvars.example`):

| Variable | Example |
|----------|---------|
| `domain_name` | `vulnbank-lab.example` |
| `record_name` | `app` |
| `admin_cidr` | `YOUR.IP.ADDRESS/32` |
| `aws_region` | `us-east-2` |

Mark `deepseek_api_key` sensitive if used.

### Dynamic AWS credentials (Terraform Cloud → AWS OIDC)

Terraform Cloud applies infrastructure without long-lived AWS keys.

1. In AWS IAM, create role **`tfc-vulnbank-infra-role`** with permissions for VPC, EC2, ELB, ACM, Route 53, Secrets Manager, IAM (scoped), SSM parameters.
2. Trust policy (replace `ORG`, `PROJECT`, `WORKSPACE`, `ACCOUNT_ID`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/app.terraform.io"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "app.terraform.io:aud": "aws.workload.identity"
        },
        "StringLike": {
          "app.terraform.io:sub": "organization:ORG:project:PROJECT:workspace:WORKSPACE:run_phase:*"
        }
      }
    }
  ]
}
```

3. Register OIDC provider `app.terraform.io` in IAM if not present (see [HashiCorp AWS dynamic credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws)).
4. In the TFC workspace **Variables**, add:

| Variable | Value |
|----------|--------|
| `TFC_AWS_PROVIDER_AUTH` | `true` |
| `TFC_AWS_RUN_ROLE_ARN` | `arn:aws:iam::ACCOUNT_ID:role/tfc-vulnbank-infra-role` |

5. Run **Plan** then **Apply**.

### After first apply

1. Note output **`route53_nameservers`**.
2. At your domain registrar, set the domain’s NS records to those nameservers.
3. Wait for DNS propagation and ACM validation (can take up to 30 minutes).
4. Open output **`website_url`** (e.g. `https://app.vulnbank-lab.example`).

## 2. GitHub Actions OIDC (deploy role)

Terraform can create the deploy role when `github_oidc_enabled = true` (default). Output **`github_deploy_role_arn`** is the role for CD.

### GitHub repository variables

In **Settings → Secrets and variables → Actions → Variables**:

| Name | Value |
|------|--------|
| `VULNBANK_AWS_ROLE_ARN` | `github_deploy_role_arn` from Terraform output |
| `AWS_REGION` | `us-east-2` |
| `VULNBANK_WEBSITE_URL` | `https://app.your-domain` |
| `VULNBANK_SSM_INSTANCE_ID_PARAM` | `/dev/vulnbank/ec2_instance_id` |
| `VULNBANK_SSM_DEPLOY_CONFIG_PARAM` | `/dev/vulnbank/deploy_config` |

Set variable `github_repository` in Terraform to match your fork (default `cyber-gp/aws-demo-projects`).

## 3. Application CD

### Automatic

- Push changes to `scripts/vuln-bank/**` or the deploy workflow on `main`.
- Run workflow **Deploy Vuln-Bank App** manually from Actions; set `app_repo_branch` to redeploy a non-default application branch without changing Terraform.

### From app repo (optional)

In `devsecops-vuln-bank`, dispatch to `aws-demo-projects`:

```yaml
# Example: repository_dispatch in app repo workflow
repository_dispatch:
  types: [vuln-bank-app-updated]
```

Target repo must be configured to accept `repository_dispatch` events.

### What deploy does

1. Assumes `VULNBANK_AWS_ROLE_ARN` via OIDC.
2. Reads EC2 id from SSM.
3. Runs [`scripts/vuln-bank/deploy.sh`](../scripts/vuln-bank/deploy.sh) on the instance via SSM.
4. `git pull --ff-only` on `/opt/vuln-bank`, refresh `.env` from Secrets Manager, rewrite the production Compose override, and `docker compose up -d --build`.
5. `curl` **`/healthz`** on the public HTTPS URL.

## 4. Operations

### SSM shell (no SSH)

```bash
aws ssm start-session --target <ec2_instance_id>
```

### SSH (break-glass)

Allowed only from `admin_cidr` in `terraform.tfvars`.

### Reset database (lab)

```bash
cd /opt/vuln-bank
docker compose -p vulnbank down -v
sudo rm -rf /data/vuln-bank/volumes/postgres_data/*
docker compose -p vulnbank up -d --build
```

## 5. Troubleshooting

| Issue | Check |
|-------|--------|
| ACM stuck pending | Route 53 NS delegated? Validation records in zone? |
| ALB unhealthy | SSM to instance: `curl localhost/healthz`, `docker compose ps` |
| SSM command failed | Instance has `AmazonSSMManagedInstanceCore`; agent running |
| GitHub OIDC denied | `sub` matches `repo:ORG/aws-demo-projects:*`; role ARN in vars |
| TFC apply denied | `TFC_AWS_RUN_ROLE_ARN` trust `sub` matches workspace |
| App missing `start.sh` | Bootstrap creates fallback `start.sh`; prefer upstream fix |

## Security notice

Vuln-Bank is **deliberately vulnerable**. Use an isolated lab account, restrict `admin_cidr`, do not store real data, and do not expose beyond training scope.

## File reference

- Terraform: [`terraform/vuln-bank/`](../terraform/vuln-bank/)
- Deploy workflow: [`.github/workflows/vuln-bank-deploy.yml`](../.github/workflows/vuln-bank-deploy.yml)
