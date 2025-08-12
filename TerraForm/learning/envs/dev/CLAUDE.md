# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Terraform Operations
```bash
# Initialize and apply infrastructure
terraform init
terraform plan
terraform apply

# Destroy infrastructure (use with caution)
terraform destroy

# Format and validate code
terraform fmt -recursive
terraform validate

# Show current state
terraform show
terraform output
```

### Development Workflow
```bash
# Navigate to dev environment
cd /Users/tomasz/local_repo/DevOps-Learning/TerraForm/learning/envs/dev

# Check git status and commit changes
git status
git add .
git commit -m "feat: description of changes"
```

### Testing Infrastructure
```bash
# Test SSH access to instances (after apply)
ssh -i ~/.ssh/id_rsa_AWS ubuntu@<public_ip>

# Test web server
curl http://<public_ip>

# Monitor logs
tail -f /var/log/cloud-init-output.log
```

## Architecture Overview

This is a **multi-AZ AWS infrastructure** using Terraform with a **modular architecture**:

### Project Structure
```
envs/dev/           # Environment-specific configurations
├── main.tf         # Main infrastructure orchestration
├── variables.tf    # Variable definitions with validation
├── terraform.tfvars # Actual values for dev environment
├── outputs.tf      # Infrastructure outputs and SSH commands
├── backend.tf      # S3 remote state configuration
└── provider.tf     # AWS provider with default tags

modules/            # Reusable infrastructure components
├── vpc/            # VPC with public/private subnets, NAT Gateway
├── ec2/            # EC2 instances with security groups
└── terraform-state-bucket/ # S3 bucket for state management
```

### Network Architecture
- **VPC**: `10.0.0.0/16` CIDR block in `eu-central-1`
- **Public Subnet**: `10.0.1.0/24` in `eu-central-1a` (web subnet)
- **Private Subnets**: 
  - App subnet: `10.0.10.0/24` in `eu-central-1b`
  - DB subnet: `10.0.20.0/24` in `eu-central-1c`
- **NAT Gateway**: Single gateway for cost optimization in dev environment

### Instance Configuration
- **Public Instance**: Ubuntu 22.04 LTS, nginx web server, bastion host functionality
- **Private Instances**: App server and DB server accessible via bastion
- **Security Groups**: Layered security with specific port access rules

### Key Design Patterns

#### Module Communication
- Modules use `for_each` with explicit maps instead of lists for predictable resource creation
- Variables have validation rules and detailed descriptions in Polish
- Outputs provide ready-to-use SSH commands and connection information

#### Cost Optimization
- Single NAT Gateway (`single_nat_gateway = true`) saves ~$45/month in dev
- `enable_nat_gateway` can be disabled entirely for maximum cost savings

#### Environment Separation
- Shared S3 bucket with different state keys per environment
- Environment-specific terraform.tfvars files
- Consistent tagging strategy with environment, project, and owner tags

#### State Management
- S3 backend with DynamoDB locking
- Shared state bucket: `terraform-state-tk-20250723200542692400000001`
- Environment-specific state keys: `dev/infrastructure.tfstate`

### Security Considerations
- SSH key management via `public_key_path` variable
- Security groups follow principle of least privilege
- Private subnets for application and database tiers
- DNS resolution enabled for service discovery

### Development Notes
- All comments and documentation are in Polish
- Code follows explicit over implicit philosophy
- Extensive use of locals and data sources for DRY principles
- Variables include detailed descriptions explaining business logic and AWS concepts