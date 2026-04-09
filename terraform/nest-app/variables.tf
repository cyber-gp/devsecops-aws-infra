# Environment 
variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "project_directory" {
  description = "Project directory name"
  type        = string
}

# VPC 
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_az1_cidr" {
  description = "Public subnet AZ1 CIDR"
  type        = string
}

variable "public_subnet_az2_cidr" {
  description = "Public subnet AZ2 CIDR"
  type        = string
}

variable "private_app_subnet_az1_cidr" {
  description = "Private app subnet AZ1 CIDR"
  type        = string
}

variable "private_app_subnet_az2_cidr" {
  description = "Private app subnet AZ2 CIDR"
  type        = string
}

variable "private_data_subnet_az1_cidr" {
  description = "Private data subnet AZ1 CIDR"
  type        = string
}

variable "private_data_subnet_az2_cidr" {
  description = "Private data subnet AZ2 CIDR"
  type        = string
}

# Secrets Manager 
variable "secret_name" {
  description = "Secrets Manager secret name"
  type        = string
}

# RDS 
variable "multi_az_deployment" {
  description = "Enable Multi-AZ deployment"
  type        = bool
}

variable "database_instance_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "database_instance_class" {
  description = "RDS instance class (e.g., db.t3.micro)"
  type        = string
}

variable "database_engine" {
  description = "Database engine (mysql, postgres, mariadb)"
  type        = string
}

variable "database_engine_version" {
  description = "Database engine version (e.g., 8.0.39)"
  type        = string
}

variable "publicly_accessible" {
  description = "Make RDS publicly accessible"
  type        = bool
}

# EC2
variable "amazon_linux_ami_id" {
  description = "Amazon Linux AMI ID"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type (e.g., t3.micro)"
  type        = string
}

variable "flyway_version" {
  description = "Flyway CLI version"
  type        = string
}

variable "sql_script_s3_uri" {
  description = "S3 URI for SQL migration script"
  type        = string
}

# ACM 
variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "alternative_names" {
  description = "Alternative domain names (SANs)"
  type        = string
}

# ALB 
variable "target_type" {
  description = "Target type (ip, instance, lambda)"
  type        = string
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

# SNS 
variable "operator_email" {
  description = "Email for SNS notifications"
  type        = string
}

# Route 53
variable "record_name" {
  description = "Route 53 record name"
  type        = string
}

# ASG
variable "web_files_s3_uri" {
  description = "S3 URI for application code"
  type        = string
}

variable "service_provider_file_s3_uri" {
  description = "S3 URI for service provider file"
  type        = string
}

variable "application_code_file_name" {
  description = "Application code file name"
  type        = string
}