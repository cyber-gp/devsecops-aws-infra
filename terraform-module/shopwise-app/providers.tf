# AWS provider
provider "aws" {
  region  = "us-east-2"
  profile = "tolani-admin" # This profile name must be specified unless the terraform plan/apply would not work

  default_tags {
    tags = {
      "Automation"  = "terraform"
      "Project"     = "nest"
      "Environment" = "dev"
    }
  }
}

 