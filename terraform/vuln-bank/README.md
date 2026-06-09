# Vuln-Bank on AWS EC2

Terraform stack for [cyber-gp/devsecops-vuln-bank](https://github.com/cyber-gp/devsecops-vuln-bank) on a single EC2 instance with Docker Compose, ALB + ACM HTTPS, Route 53, and EBS persistence.

## Quick start

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and set `domain_name`, `admin_cidr`, and TFC org in `versions.tf`.
2. In Terraform Cloud, add sensitive workspace variables **`db_password`** (required) and **`deepseek_api_key`** (optional).
3. Follow [docs/vuln-bank-setup.md](../../docs/vuln-bank-setup.md) for Terraform Cloud, OIDC, and GitHub Actions.
4. Apply via Terraform Cloud (recommended).

## Layout

| File | Purpose |
|------|---------|
| `vpc.tf`, `nat-gateway.tf` | Networking |
| `ec2.tf`, `user-data.sh.tpl` | App host bootstrap |
| `alb.tf`, `route53-acm.tf` | HTTPS edge |
| `secrets.tf`, `iam.tf` | AWS Secrets Manager (values from TFC variables) and EC2 role |
| `github-oidc.tf` | GitHub Actions deploy role |
| `ssm.tf` | SSM parameters for CD workflow |
