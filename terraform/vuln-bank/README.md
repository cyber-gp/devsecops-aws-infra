# Vuln-Bank on AWS EC2

Terraform stack for [cyber-gp/devsecops-vuln-bank](https://github.com/cyber-gp/devsecops-vuln-bank) on a single EC2 instance with Docker Compose, ALB + ACM HTTPS, Route 53, and EBS persistence.

## Quick start

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and set `domain_name`, `admin_cidr`, and TFC org in `versions.tf`.
2. Follow [docs/vuln-bank-setup.md](../../docs/vuln-bank-setup.md) for Terraform Cloud, OIDC, and GitHub Actions.
3. Apply via Terraform Cloud (recommended) or `terraform apply` with `TF_API_TOKEN`.

## Layout

| File | Purpose |
|------|---------|
| `vpc.tf`, `nat-gateway.tf` | Networking |
| `ec2.tf`, `user-data.sh.tpl` | App host bootstrap |
| `alb.tf`, `route53-acm.tf` | HTTPS edge |
| `secrets.tf`, `iam.tf` | App secrets and EC2 role |
| `github-oidc.tf` | GitHub Actions deploy role |
| `ssm.tf` | SSM parameters for CD workflow |
