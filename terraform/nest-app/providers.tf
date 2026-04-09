# AWS provider
provider "aws" {
  region  = var.region
  profile = "tolani-admin"
  default_tags {
    tags = {
      "Automation"  = "terraform"
      "Project"     = var.project_name
      "Environment" = var.environment
    }
  }
}

 