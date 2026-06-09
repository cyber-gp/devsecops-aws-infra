terraform {
  required_version = ">= 1.5.0"

  cloud {
    organization = "REPLACE_WITH_YOUR_TFC_ORG"

    workspaces {
      name = "vuln-bank-ec2"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
