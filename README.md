# AWS Demo Projects - Comprehensive Guide

A complete demonstration of containerized application deployment on AWS using multiple approaches, infrastructure as code, CI/CD automation, and best practices for DevOps.

## Table of Contents

- [Project Overview](#project-overview)
- [Key Concepts](#key-concepts)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Deployment Approaches](#deployment-approaches)
- [AWS Services Used](#aws-services-used)
- [Step-by-Step Implementation Guides](#step-by-step-implementation-guides)
- [Quick Start](#quick-start)
- [Troubleshooting](#troubleshooting)

---

## Project Overview

This repository demonstrates how to deploy a containerized NestJS web application on AWS using multiple approaches:

1. **Docker + Docker Compose** - Local development and testing
2. **Terraform + EC2** - Infrastructure as Code for traditional cloud deployment
3. **Kubernetes (EKS)** - Container orchestration on AWS
4. **ECS + Fargate** - AWS-managed container service
5. **CI/CD Pipeline** - Automated deployment using GitHub Actions

Each approach includes:
- Complete infrastructure setup
- Database migration scripts
- Security configurations
- Health checks and monitoring
- Troubleshooting guides

---

## Key Concepts

### 1. **Containerization (Docker)**
Containerization packages your application and all its dependencies into a standardized unit called a container. This ensures your app runs the same way everywhere.

**Why it matters:**
- Eliminates "works on my machine" problems
- Easy to scale and deploy
- Lightweight and fast to start

**In this project:** We build Docker images for the NestJS application with all dependencies configured.

### 2. **Infrastructure as Code (Terraform)**
Instead of clicking buttons in AWS console, you write code to define your infrastructure. Terraform reads this code and creates/manages AWS resources.

**Why it matters:**
- Reproducible infrastructure
- Version control for your infrastructure
- Easy to scale and maintain
- Disaster recovery ready

**In this project:** Terraform modules define VPC, RDS, ALB, EC2 instances, security groups, and more.

### 3. **Container Orchestration (Kubernetes/EKS)**
Manages containers at scale - handles deployment, scaling, networking, and lifecycle management.

**Why it matters:**
- Automatic scaling based on demand
- Self-healing (restarts failed containers)
- Rolling updates with zero downtime
- Multi-container coordination

**In this project:** EKS manifests define Kubernetes deployments, services, and configurations.

### 4. **Continuous Integration/Continuous Deployment (CI/CD)**
Automatically tests, builds, and deploys your application whenever you push code.

**Why it matters:**
- Faster time to market
- Reduces manual errors
- Automated testing catches bugs early
- One-click deployments

**In this project:** GitHub Actions workflows automate building, testing, and deploying to ECS.

### 5. **Infrastructure Patterns**
- **High Availability:** Multiple instances across availability zones
- **Load Balancing:** Distributes traffic across instances
- **Auto-Scaling:** Automatically adjusts capacity based on demand
- **Security Groups:** Virtual firewalls controlling traffic

---

## Project Structure

```
aws-demo-projects/
├── docker/                          # Containerization
│   ├── nest-app/                   # Basic Docker setup for development
│   │   ├── Dockerfile              # Multi-stage production build
│   │   ├── Dockerfile.dev          # Development build
│   │   ├── build-push-image.sh     # Script to build and push to ECR
│   │   └── start-services.sh       # Script to start services locally
│   │
│   └── nest-app-cicd/              # Docker setup for CI/CD pipeline
│       ├── Dockerfile              # Optimized for automated builds
│       ├── build-image.sh          # Build script
│       ├── push-image.sh           # Push to ECR script
│       └── manual/                 # Manual deployment scripts
│
├── kubernetes/eks/                  # Kubernetes deployment
│   └── nest-app/
│       ├── deployment.yaml         # K8s Deployment manifest
│       ├── service.yaml            # K8s Service manifest
│       ├── secret-provider-class.yaml  # AWS Secrets Manager integration
│       ├── aws-auth-patch.yaml     # IAM authentication
│       └── eks-deployment.sh       # Deployment automation script
│
├── terraform/                       # Infrastructure as Code
│   └── nest-app/
│       ├── vpc.tf                  # Virtual Private Cloud setup
│       ├── rds.tf                  # Relational Database Service
│       ├── alb.tf                  # Application Load Balancer
│       ├── asg.tf                  # Auto Scaling Group
│       ├── ec2-profile-role.tf    # IAM roles and policies
│       ├── security-group.tf       # Firewall rules
│       ├── eice.tf                 # EC2 Instance Connect Endpoint
│       ├── nat-gateway.tf          # NAT Gateway for private subnets
│       ├── acm.tf                  # SSL/TLS certificates
│       ├── route-53.tf             # DNS configuration
│       ├── sns.tf                  # Simple Notification Service
│       ├── secrets_manager.tf      # Secrets management
│       ├── db-migrate-server.tf   # Database migration setup
│       ├── providers.tf            # AWS provider configuration
│       ├── backend.tf              # Terraform state backend
│       ├── terraform.tf            # Terraform version
│       ├── variables.tf            # Input variables
│       └── outputs.tf              # Output values
│
├── terraform-module/                # Reusable Terraform modules
│   └── nest-app/
│       ├── main.tf
│       ├── providers.tf
│       ├── backend.tf
│       └── terraform.tf
│
├── terraform-module-ecs-cicd/       # ECS-specific Terraform modules for CI/CD
│   └── nest-app/
│       ├── main.tf
│       ├── providers.tf
│       ├── backend.tf
│       └── terraform.tf
│
├── scripts/                         # Utility scripts
│   ├── docker-install.sh           # Docker installation script
│   ├── git-lfs-install.sh          # Git Large File Storage setup
│   └── db-migrate-script.sh        # Database migration utility
│
├── troubleshooting/                # Troubleshooting guides
│   ├── troubleshooting-csi-driver-token-config.md
│   └── troubleshooting-eks-node-issue.md
│
├── devops-quick-reference.md       # Quick reference for common commands
├── project-7-agenda.md             # CI/CD project implementation steps
└── README.md                        # This file
```

---

## Prerequisites

Before you start, ensure you have the following installed and configured:

### Required Software

1. **AWS Account**
   - Create a free tier account at [aws.amazon.com](https://aws.amazon.com)
   - Configure AWS credentials locally:
     ```bash
     aws configure
     ```

2. **Git & GitHub**
   - Install Git: https://git-scm.com/downloads
   - Create GitHub account: https://github.com
   - Generate SSH key pair:
     ```bash
     ssh-keygen -t ed25519 -C "your-email@example.com"
     ```

3. **Docker**
   - Install Docker Desktop: https://www.docker.com/products/docker-desktop
   - Or run the installation script:
     ```bash
     chmod +x scripts/docker-install.sh
     ./scripts/docker-install.sh
     ```

4. **Terraform**
   - Download: https://www.terraform.io/downloads
   - Verify installation:
     ```bash
     terraform --version
     ```

5. **kubectl (for Kubernetes)**
   - Install: https://kubernetes.io/docs/tasks/tools/
   - Verify:
     ```bash
     kubectl version --client
     ```

6. **AWS CLI**
   - Install: https://aws.amazon.com/cli/
   - Verify:
     ```bash
     aws --version
     ```

### AWS Permissions Required

Your AWS IAM user needs permissions for:
- EC2 (instances, security groups, auto-scaling)
- RDS (database management)
- ECR (container registry)
- ECS/Fargate (container service)
- EKS (managed Kubernetes)
- VPC (networking)
- IAM (roles and policies)
- Secrets Manager (secure credentials)
- Route 53 (DNS)
- ACM (SSL certificates)
- ALB (load balancing)
- S3 (Terraform state storage)

---

## Deployment Approaches

Each approach has different use cases. Choose based on your needs:

| Approach | Best For | Complexity | Cost | Scalability |
|----------|----------|-----------|------|-------------|
| **Docker + Docker Compose** | Local development & testing | ⭐ Low | Free | Single machine |
| **Terraform + EC2** | Traditional cloud, full control | ⭐⭐ Medium | Low-Medium | Manual scaling |
| **Kubernetes (EKS)** | Enterprise, microservices | ⭐⭐⭐ High | Medium | Auto-scaling |
| **ECS + Fargate** | AWS-native, serverless containers | ⭐⭐ Medium | Low-Medium | Auto-scaling |
| **CI/CD Pipeline** | Automated deployment | ⭐⭐⭐ High | Low-Medium | Varies |

---

## AWS Services Used

### Compute
- **EC2** - Virtual servers
- **ECS** - Container orchestration (AWS-native)
- **EKS** - Managed Kubernetes
- **Lambda** - Serverless compute (potential)

### Storage & Database
- **RDS** - Managed relational database (MySQL/PostgreSQL)
- **S3** - Object storage for Terraform state
- **EBS** - Block storage for EC2 instances

### Networking
- **VPC** - Virtual Private Cloud
- **ALB** - Application Load Balancer
- **NAT Gateway** - Outbound traffic for private subnets
- **Route 53** - DNS management
- **Security Groups** - Virtual firewalls

### Security & Management
- **IAM** - Identity and access management
- **Secrets Manager** - Credential management
- **ACM** - SSL/TLS certificates
- **ECR** - Container image registry

### Monitoring & Integration
- **SNS** - Simple Notification Service (alerts)
- **CloudWatch** - Monitoring and logging
- **GitHub Actions** - CI/CD automation

---

## Step-by-Step Implementation Guides

### Approach 1: Docker + Docker Compose (Local Development)

**Time Required:** 15-30 minutes  
**Difficulty:** Beginner  
**Best For:** Local development and testing

#### Step 1: Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/aws-demo-projects.git
cd aws-demo-projects
```

#### Step 2: Prepare Environment Variables
Create a `.env` file in the `docker/nest-app` directory:
```bash
PROJECT_NAME=nest-app
ENVIRONMENT=dev
DOMAIN_NAME=example.com
RDS_ENDPOINT=your-rds-endpoint
RDS_DB_NAME=nest_db
RDS_DB_USERNAME=admin
RDS_DB_PASSWORD=YourSecurePassword123!
GITHUB_USERNAME=your-github-username
REPOSITORY_NAME=aws-demo-projects
```

#### Step 3: Build Docker Image
```bash
cd docker/nest-app
docker build \
  --build-arg PROJECT_NAME=nest-app \
  --build-arg ENVIRONMENT=dev \
  --build-arg DOMAIN_NAME=example.com \
  --build-arg RDS_ENDPOINT=localhost \
  --build-arg RDS_DB_NAME=nest_db \
  --build-arg RDS_DB_USERNAME=admin \
  -t nest:dev .
```

#### Step 4: Verify the Image
```bash
docker image ls | grep nest
```

#### Step 5: Start Services
```bash
chmod +x start-services.sh
./start-services.sh
```

#### Step 6: Test the Application
```bash
# Check if container is running
docker ps

# View logs
docker logs <container_id>

# Access the application
curl http://localhost:3000
```

### Approach 2: Terraform + EC2 (Infrastructure as Code)

**Time Required:** 45-60 minutes  
**Difficulty:** Intermediate  
**Best For:** Production-like infrastructure, full control

#### Step 1: Initialize Terraform
```bash
cd terraform/nest-app
terraform init
```

#### Step 2: Review and Update terraform.tfvars
```bash
# Open terraform.tfvars and update with your values
nano terraform.tfvars
```

Key variables to set:
- `aws_region` - Your AWS region (e.g., us-east-1)
- `environment` - Environment name (dev, staging, prod)
- `instance_type` - EC2 instance type (t3.micro for free tier)
- `domain_name` - Your domain name
- `rds_username` - Database admin username
- `rds_password` - Strong database password

#### Step 3: Plan Infrastructure
```bash
terraform plan -out=tfplan
```

Review the output to see what resources will be created.

#### Step 4: Apply Infrastructure
```bash
terraform apply tfplan
```

Wait for all resources to be created. This typically takes 5-10 minutes.

#### Step 5: Retrieve Outputs
```bash
terraform output
```

Important outputs:
- `alb_dns_name` - Load balancer URL
- `rds_endpoint` - Database endpoint
- `ec2_instance_id` - Your EC2 instance ID

#### Step 6: Build and Push Docker Image to ECR
```bash
# Get ECR repository URI from outputs
ECR_REPO=$(terraform output -raw ecr_repository_uri)

# Build image
cd ../../docker/nest-app
docker build \
  --build-arg PROJECT_NAME=nest-app \
  --build-arg ENVIRONMENT=prod \
  --build-arg RDS_ENDPOINT=$RDS_ENDPOINT \
  --build-arg RDS_DB_NAME=nest_db \
  --build-arg RDS_DB_USERNAME=admin \
  -t $ECR_REPO:1.0.0 .

# Login to ECR and push
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REPO

docker push $ECR_REPO:1.0.0
```

#### Step 7: Verify Deployment
```bash
# Check if application is running
curl http://<ALB_DNS_NAME>

# Check RDS database
mysql -h <RDS_ENDPOINT> -u admin -p nest_db
```

### Approach 3: Kubernetes (EKS)

**Time Required:** 60-90 minutes  
**Difficulty:** Advanced  
**Best For:** Complex microservices, enterprise deployments

#### Step 1: Create EKS Cluster via Terraform

First, use Terraform to create the EKS cluster:
```bash
cd terraform/nest-app
# Ensure terraform.tfvars includes EKS configuration
terraform plan -out=tfplan
terraform apply tfplan
```

#### Step 2: Configure kubectl
```bash
# Get cluster credentials
aws eks update-kubeconfig \
  --name $(terraform output -raw eks_cluster_name) \
  --region us-east-1

# Verify connection
kubectl get nodes
```

#### Step 3: Prepare Docker Image
```bash
# Build and push image to ECR (same as Terraform approach)
```

#### Step 4: Update Kubernetes Manifests
Edit `eks/nest-app/deployment.yaml`:
```yaml
spec:
  containers:
  - name: dev-nest-eks-container
    image: YOUR_ECR_REPO_URI/nest:1.0.0  # Update this
```

#### Step 5: Create Kubernetes Namespace
```bash
kubectl create namespace dev-nest-eks-namespace
```

#### Step 6: Deploy Application
```bash
cd eks/nest-app

# Apply configuration
kubectl apply -f secret-provider-class.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Verify deployment
kubectl get pods -n dev-nest-eks-namespace
kubectl get svc -n dev-nest-eks-namespace
```

#### Step 7: Access Application
```bash
# Get external IP
kubectl get svc -n dev-nest-eks-namespace

# Wait for external IP to be assigned (may take 2-3 minutes)
# Then access via: http://<EXTERNAL_IP>
```

### Approach 4: ECS + Fargate (AWS-Native)

**Time Required:** 30-45 minutes  
**Difficulty:** Intermediate  
**Best For:** AWS-native serverless containers

#### Step 1: Create Infrastructure with Terraform
```bash
cd terraform-module-ecs-cicd/nest-app
terraform init
terraform plan
terraform apply
```

#### Step 2: Build Docker Image
```bash
cd ../../docker/nest-app-cicd
chmod +x build-image.sh
./build-image.sh
```

#### Step 3: Push to ECR
```bash
chmod +x push-image.sh
./push-image.sh
```

#### Step 4: Verify Deployment
```bash
# Check ECS service
aws ecs describe-services \
  --cluster nest-prod-cluster \
  --services nest-app-service

# Check task status
aws ecs list-tasks \
  --cluster nest-prod-cluster \
  --service-name nest-app-service
```

### Approach 5: CI/CD with GitHub Actions

**Time Required:** 90-120 minutes  
**Difficulty:** Advanced  
**Best For:** Automated deployment on every push

#### Step 1: Set Up Terraform for CI/CD
```bash
cd terraform/nest-app

# Update backend.tf to remove profile
# Update providers.tf to use environment variables instead
```

#### Step 2: Create GitHub Workflows Directory
```bash
mkdir -p .github/workflows
```

#### Step 3: Configure GitHub Secrets
In your GitHub repository settings, add secrets:
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- `AWS_REGION` - Your AWS region (e.g., us-east-1)
- `SLACK_WEBHOOK_URL` - Slack notification webhook

#### Step 4: Create CI/CD Workflow File
Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to AWS ECS

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: nest
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
      
      - name: Push to ECR
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: nest
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
      
      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster nest-prod-cluster \
            --service nest-app-service \
            --force-new-deployment
      
      - name: Notify Slack
        if: always()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
            -H 'Content-Type: application/json' \
            -d '{"text": "Deployment ${{ job.status }}"}'
```

#### Step 5: Test the Workflow
```bash
# Push changes to trigger workflow
git add .github/workflows/deploy.yml
git commit -m "Add CI/CD workflow"
git push origin main
```

#### Step 6: Monitor Deployment
- Go to GitHub Actions tab
- Watch the workflow run
- Check Slack for notifications
- Verify application is running on AWS

---

## Quick Start

### For Quick Local Testing (Recommended First Step)
```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/aws-demo-projects.git
cd aws-demo-projects

# 2. Build Docker image
cd docker/nest-app
docker build -t nest:local .

# 3. Run container
docker run -p 3000:3000 nest:local

# 4. Test
curl http://localhost:3000
```

### For Production on AWS (Full Stack)
```bash
# 1. Clone and configure
git clone https://github.com/YOUR_USERNAME/aws-demo-projects.git
cd aws-demo-projects/terraform/nest-app

# 2. Update terraform.tfvars
nano terraform.tfvars

# 3. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 4. Build and push Docker image
cd ../../docker/nest-app
# ... build and push steps ...

# 5. Access application via load balancer URL
```

---

## Common Operations

### Database Migration
```bash
chmod +x scripts/db-migrate-script.sh
./scripts/db-migrate-script.sh
```

### View Terraform State
```bash
cd terraform/nest-app
terraform state list
terraform state show aws_db_instance.main
```

### Scale Application (EC2/Terraform)
```bash
cd terraform/nest-app

# Edit variables.tf or terraform.tfvars
nano terraform.tfvars

# Update desired_count to scale
terraform plan
terraform apply
```

### Scale Application (EKS/Kubernetes)
```bash
# Scale deployment
kubectl scale deployment dev-nest-eks-deployment \
  --replicas=3 \
  -n dev-nest-eks-namespace

# Verify
kubectl get pods -n dev-nest-eks-namespace
```

### View Logs

**Docker:**
```bash
docker logs -f <container_id>
```

**ECS:**
```bash
aws logs tail /ecs/nest-app --follow
```

**EKS:**
```bash
kubectl logs -f <pod_name> -n dev-nest-eks-namespace
```

### Clean Up Resources

**Docker:**
```bash
docker system prune -a --volumes
```

**Terraform (Destroys all AWS resources):**
```bash
cd terraform/nest-app
terraform destroy
```

**Kubernetes:**
```bash
kubectl delete namespace dev-nest-eks-namespace
```

---

## Monitoring & Health Checks

### Application Health Check
```bash
# Check if application is responding
curl -I http://<application_url>

# Expected: HTTP/1.1 200 OK
```

### Database Connectivity
```bash
# Test RDS connection
mysql -h <rds_endpoint> -u <username> -p <database>

# Or using AWS CLI
aws rds describe-db-instances \
  --query 'DBInstances[0].DBInstanceStatus'
```

### AWS Resource Status
```bash
# Check EC2 instances
aws ec2 describe-instances --query 'Reservations[0].Instances[0].State'

# Check ECS services
aws ecs describe-services \
  --cluster <cluster_name> \
  --services <service_name>

# Check EKS cluster
aws eks describe-cluster --name <cluster_name>
```

---

## Troubleshooting

### Docker Image Build Fails
**Problem:** Docker build fails with permission errors  
**Solution:**
```bash
# Ensure Docker daemon is running
docker ps

# On Linux, may need to add user to docker group
sudo usermod -aG docker $USER
```

### Terraform Apply Hangs
**Problem:** Terraform seems stuck or very slow  
**Solution:**
```bash
# Check AWS API rate limits
aws service-quotas list-service-quotas \
  --service-code ec2

# Try applying with more verbose output
terraform apply -out=tfplan -lock-timeout=5m

# If timeout occurs, you can re-apply
terraform apply tfplan
```

### Database Connection Refused
**Problem:** Cannot connect to RDS database  
**Solution:**
```bash
# Check security group allows inbound traffic
aws ec2 describe-security-groups \
  --query 'SecurityGroups[0].IpPermissions'

# Check RDS is in available state
aws rds describe-db-instances \
  --query 'DBInstances[0].DBInstanceStatus'

# Verify network connectivity
nc -zv <rds_endpoint> 3306
```

### EKS Pod Stuck in Pending
**Problem:** Kubernetes pod won't start  
**Solution:**
```bash
# Check pod events
kubectl describe pod <pod_name> -n <namespace>

# Check node resources
kubectl top nodes

# Check logs
kubectl logs <pod_name> -n <namespace> --previous
```

### ECR Push Fails Authentication
**Problem:** "unauthorized: authentication required"  
**Solution:**
```bash
# Re-authenticate with ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ecr_uri>

# Verify login was successful
docker ps
```

### See Additional Troubleshooting Guides
- [EKS Node Issues](troubleshooting/troubleshooting-eks-node-issue.md)
- [CSI Driver Token Configuration](troubleshooting/troubleshooting-csi-driver-token-config.md)

---

## Additional Resources

### AWS Documentation
- [AWS for Beginners](https://aws.amazon.com/getting-started/)
- [EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [RDS Documentation](https://docs.aws.amazon.com/rds/)
- [ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [EKS Documentation](https://docs.aws.amazon.com/eks/)

### DevOps & Cloud
- [Terraform Learn](https://learn.hashicorp.com/terraform)
- [Docker Tutorials](https://docs.docker.com/get-started/)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [GitHub Actions](https://github.com/features/actions)

### Quick Reference
- See [devops-quick-reference.md](devops-quick-reference.md) for common commands
- See [project-agenda.md](project-7-agenda.md) for detailed CI/CD implementation steps

---

## Notes for Implementation

### When Starting Out
1. **Begin with Docker** - Understand containerization first (Approach 1)
2. **Move to Terraform** - Learn infrastructure as code (Approach 2)
3. **Explore Kubernetes** - Understand orchestration at scale (Approach 3)
4. **Try ECS** - Simpler AWS-native alternative to K8s (Approach 4)
5. **Implement CI/CD** - Automate your deployments (Approach 5)

### Security Best Practices
- Never commit AWS credentials to Git
- Use IAM roles instead of access keys when possible
- Enable MFA on AWS account
- Use Secrets Manager for sensitive data
- Implement least privilege access (principle of least privilege)
- Regularly rotate credentials and keys

### Cost Optimization
- Use AWS free tier for learning
- Clean up resources after testing (`terraform destroy`)
- Use spot instances for non-critical workloads
- Monitor your spending with AWS Cost Explorer

---

## Contributing

Have improvements or found issues? 
1. Fork the repository
2. Create a branch (`git checkout -b feature/improvement`)
3. Make changes and test locally
4. Commit changes (`git commit -am 'Add improvement'`)
5. Push to branch (`git push origin feature/improvement`)
6. Open a Pull Request

---

## License

This project is provided as-is for educational and demonstration purposes.

---

## FAQ

**Q: Which approach should I use for production?**  
A: For true enterprise production, use EKS (Kubernetes) for maximum flexibility and portability, or ECS for AWS-native simplicity.

**Q: How much will this cost to run?**  
A: With AWS free tier, most of this is free for 12 months. After that, expect $20-100/month depending on configuration.

**Q: Can I use this with my own application?**  
A: Yes! Customize the Docker images, Terraform configurations, and Kubernetes manifests for your specific application.

**Q: How do I prevent accidental resource deletion?**  
A: Use Terraform state locking (backend.tf), enable MFA delete on S3, and use IAM policies to restrict permissions.

**Q: What if I make a mistake with Terraform?**  
A: Terraform keeps a state file. You can `terraform destroy` to clean up, then carefully review your code before `terraform apply` again.

---

**Last Updated:** 2026  
**Version:** 1.0.0