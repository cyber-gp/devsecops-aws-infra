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

# Create Security Groups
module "sg" {
  source       = "git::ssh://git@github.com/Tolani-Akintayo/aws-modules.git//security-groups"
  environment  = module.vpc.environment
  project_name = module.vpc.project_name
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr
}

# Create eice
module "eice" {
  source                    = "git::ssh://git@github.com/Tolani-Akintayo/aws-modules.git//eice"
  project_name              = module.vpc.project_name
  environment               = module.vpc.environment
  private_app_subnet_az1_id = module.vpc.private_app_subnet_az1_id
  eice_security_group_id    = module.sg.eice_security_group_id
}

# Create Secrets Manager
module "secrets-manager" {
  source    = "git::ssh://git@github.com/Tolani-Akintayo/aws-modules.git//secrets-manager"
  secret_id = "dev-nest-secrets"
}

# Create RDS
module "rds" {
  source                       = "git::ssh://git@github.com/Tolani-Akintayo/aws-modules.git//rds"
  environment                  = module.vpc.environment
  project_name                 = module.vpc.project_name
  private_data_subnet_az1_id   = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id   = module.vpc.private_data_subnet_az2_id
  database_engine              = "mysql"
  database_engine_version      = "8.4.8"
  multi_az_deployment          = false
  database_instance_identifier = "app-db"
  rds_db_username              = module.secrets-manager.rds_db_username
  rds_db_password              = module.secrets-manager.rds_db_password
  rds_db_secret_name           = module.secrets-manager.rds_db_username
  database_instance_class      = "db.t3.micro"
  database_security_group_id   = module.sg.database_security_group_id
  availability_zone_1          = module.vpc.availability_zone_1
  publicly_accessible          = false
}

# Create ec2 instance profile
module "ec2-instance-profile" {
  source       = "git::ssh://git@github.com/Tolani-Akintayo/aws-modules.git//iam/ec2-instance-profile"
  project_name = module.vpc.project_name
  environment  = module.vpc.environment
}

# Create Data Migration server
module "db-migrate-server" {
  source                              = "git::ssh://git@github.com/Tolani-Akintayo/aws-modules.git//db-migrate-server"
  amazon_linux_ami_id                 = "ami-051de6a4e7ae45f77"
  ec2_instance_type                   = "t2.micro"
  private_app_subnet_az1_id           = module.vpc.private_app_subnet_az1_id
  db_migrate_server_security_group_id = module.sg.db_migrate_server_security_group_id
  ec2_instance_profile_role_name      = module.ec2-instance-profile.ec2_instance_profile_role_name
  flyway_version                      = "11.20.2"
  sql_script_s3_uri                   = "s3://dev-app-code-files/V1__shopwise.sql"
  rds_endpoint                        = module.rds.rds_endpoint
  rds_db_secret_name                  = module.secrets-manager.rds_db_secret_name
  rds_db_username                     = module.secrets-manager.rds_db_username
  rds_db_password                     = module.secrets-manager.rds_db_password
  project_name                        = module.vpc.project_name
  environment                         = module.vpc.environment
}

# Create Certificate Manager
module "acm" {
  source            = "git::ssh://git@github.com/Tolani-Akintayo/aws-modules.git//acm"
  domain_name       = "tolaniakintayo.xyz"
  alternative_names = "*.tolaniakintayo.xyz"
}