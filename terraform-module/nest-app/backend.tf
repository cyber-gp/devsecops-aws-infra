# S3 backend with DynamoDB for state locking
terraform {
  backend "s3" {
    bucket         = "dev-nest-terraform-state"
    key            = "terraform-module/nest/ecs/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "dev-nest-terraform-lock"
    profile        = "tolani-admin" # This profile name must be specified unless the terraform init would not work
  }
}
