provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Automation  = "terraform"
      Project     = var.project_name
      Environment = var.environment
      Application = "vuln-bank"
    }
  }
}
