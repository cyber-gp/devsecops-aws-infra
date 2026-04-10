# Create VPC 
module "vpc" {
  source                       = "git::ssh://git@github.com/Tolani-Akintayo/aws-modules.git//vpc"
  region                       = "us-east-2"
  project_name                 = "shopwise"
  environment                  = "dev"
  project_directory            = "shopwise-app"
  vpc_cidr                     = "10.0.0.0/16"
  public_subnet_az1_cidr       = "10.0.0.0/24"
  public_subnet_az2_cidr       = "10.0.1.0/24"
  private_app_subnet_az1_cidr  = "10.0.2.0/24"
  private_app_subnet_az2_cidr  = "10.0.3.0/24"
  private_data_subnet_az1_cidr = "10.0.4.0/24"
  private_data_subnet_az2_cidr = "10.0.5.0/24"
}

# Creat Nat Gateway
module "nat-gw" {
  source                     = "git::ssh://git@github.com/Tolani-Akintayo/aws-modules.git//nat-gateway"
  project_name               = module.vpc.project_name
  environment                = module.vpc.environment
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  internet_gateway           = module.vpc.internet_gateway.id
  vpc_id                     = module.vpc.vpc_id
  private_app_subnet_az1_id  = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id  = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id
}