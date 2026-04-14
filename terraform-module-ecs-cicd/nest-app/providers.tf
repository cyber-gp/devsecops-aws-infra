# AWS provider
provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      "Automation"  = "terraform"
      "Project"     = "nest"
      "Environment" = "dev"
    }
  }
}

 