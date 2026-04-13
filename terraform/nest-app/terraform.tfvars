# Environment
region            = "us-east-2"
project_name      = "nest"
environment       = "dev"
project_directory = "nest-app"

# VPC
vpc_cidr                     = "10.0.0.0/16"
public_subnet_az1_cidr       = "10.0.0.0/24"
public_subnet_az2_cidr       = "10.0.1.0/24"
private_app_subnet_az1_cidr  = "10.0.2.0/24"
private_app_subnet_az2_cidr  = "10.0.3.0/24"
private_data_subnet_az1_cidr = "10.0.4.0/24"
private_data_subnet_az2_cidr = "10.0.5.0/24"

# Secrets Manager
secret_name = "dev-nest-secrets"

# RDS
multi_az_deployment          = false
database_instance_identifier = "app-db"
database_instance_class      = "db.t3.micro"
database_engine              = "mysql"
database_engine_version      = "8.4.8"
publicly_accessible          = false

# EC2
amazon_linux_ami_id = "ami-051de6a4e7ae45f77"
ec2_instance_type   = "t2.micro"
flyway_version      = "11.20.2"
sql_script_s3_uri   = "s3://dev-app-code-files/nest/V1__nest.sql"

# ACM
domain_name       = "tolaniakintayo.xyz"
alternative_names = "*.tolaniakintayo.xyz"

# ALB
target_type       = "instance"
health_check_path = "/index.php"

# SNS
operator_email = "hello@tolaniakintayo.xyz"

# Route 53
record_name = "nest"

# ASG
web_files_s3_uri             = "s3://dev-app-code-files/nest/nest.zip"
service_provider_file_s3_uri = "s3://dev-app-code-files/nest/AppServiceProvider.php"
application_code_file_name   = "nest"

