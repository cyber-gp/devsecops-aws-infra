variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "vulnbank"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_az1_cidr" {
  type    = string
  default = "10.1.0.0/24"
}

variable "public_subnet_az2_cidr" {
  type    = string
  default = "10.1.1.0/24"
}

variable "private_app_subnet_az1_cidr" {
  type    = string
  default = "10.1.2.0/24"
}

variable "private_app_subnet_az2_cidr" {
  type    = string
  default = "10.1.3.0/24"
}

variable "domain_name" {
  description = "Route 53 hosted zone and ACM primary domain (register and delegate NS)"
  type        = string
}

variable "record_name" {
  description = "DNS record prefix (app.example.com when record_name is app)"
  type        = string
  default     = "app"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ebs_size_gb" {
  type    = number
  default = 30
}

variable "admin_cidr" {
  description = "CIDR allowed for SSH to EC2 (use your public IP/32)"
  type        = string
  default     = "0.0.0.0/32"
}

variable "app_repo_url" {
  type    = string
  default = "https://github.com/cyber-gp/devsecops-vuln-bank.git"
}

variable "app_repo_branch" {
  type    = string
  default = "main"
}

variable "health_check_path" {
  type    = string
  default = "/healthz"
}

variable "github_repository" {
  description = "GitHub repo for OIDC deploy role trust (org/repo)"
  type        = string
  default     = "cyber-gp/aws-demo-projects"
}

variable "github_oidc_enabled" {
  description = "Create GitHub Actions OIDC IAM role for SSM deploy"
  type        = bool
  default     = true
}

variable "deepseek_api_key" {
  description = "Optional DeepSeek API key for AI features (leave empty for mock mode)"
  type        = string
  sensitive   = true
  default     = ""
}
