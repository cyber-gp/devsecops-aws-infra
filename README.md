# AWS Demo Projects — Vuln-Bank on EC2

Infrastructure and CI/CD to deploy [cyber-gp/devsecops-vuln-bank](https://github.com/cyber-gp/devsecops-vuln-bank) on AWS:

- **Terraform Cloud** — VPC, EC2, EBS, ALB, ACM, Route 53
- **Docker Compose** on EC2 — Flask app + PostgreSQL (app cloned from GitHub at bootstrap/CD)
- **GitHub Actions (OIDC)** — application deploy via SSM (no SSH keys)

## Repository layout

```
aws-demo-projects/
├── terraform/vuln-bank/     # Infrastructure (Terraform Cloud)
├── scripts/vuln-bank/         # SSM deploy script
├── .github/workflows/         # vuln-bank-deploy.yml
└── docs/
    ├── vuln-bank-setup.md     # Full setup guide
    └── iam/                   # TFC OIDC trust policy example
```

## Quick start

1. Read [docs/vuln-bank-setup.md](docs/vuln-bank-setup.md).
2. Set your Terraform Cloud org in `terraform/vuln-bank/versions.tf`.
3. Copy `terraform/vuln-bank/terraform.tfvars.example` → `terraform.tfvars` and configure `domain_name`, `admin_cidr`.
4. Apply via Terraform Cloud; delegate domain NS records to output `route53_nameservers`.
5. Set GitHub Actions variables (`VULNBANK_AWS_ROLE_ARN`, `AWS_REGION`, `VULNBANK_WEBSITE_URL`).
6. Run the **Deploy Vuln-Bank App** workflow (or push changes under `scripts/vuln-bank/`).

## Application source

The app is **not** vendored in this repo. It is pulled at runtime from:

`https://github.com/cyber-gp/devsecops-vuln-bank.git`

## Security warning

Vuln-Bank is intentionally vulnerable — for education and lab use only. Do not use with real data or in production.
