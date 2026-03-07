# AWS Enterprise Deployment Guide
**Architect:** Kehinde (Kenny) Samson Ogunlowo

## Why This Architecture?

### 3-AZ NAT Gateways (not 1)
Single NAT Gateway creates an AZ dependency. At BP Refinery a single NAT failure caused 45-minute outages.
3 NAT Gateways costs ~$100/month extra but provides true multi-AZ HA.

### IMDSv2 Required on all nodes
IMDSv1 SSRF allows attackers to steal IAM credentials. The Capital One breach ($270M fine) was
directly exploitable via IMDSv1. IMDSv2 requires a PUT request with a TTL token.
Ref: https://aws.amazon.com/blogs/security/defense-in-depth-open-firewalls-reverse-proxies-ssrf-vulnerabilities-ec2-instance-metadata-service/

### Aurora vs RDS Single Instance
Aurora provides 6-way replication with <30s failover. Standard RDS Multi-AZ takes 60-120s.
For HIPAA environments, shorter RTO justifies the ~15% cost premium.

### VPC Endpoints for S3/ECR
Without endpoints, container image pulls leave the VPC. Endpoints keep AWS service traffic
inside the private network — required for CMMC network boundary compliance.

### OIDC for CI/CD (not IAM keys)
OIDC-based federation gives CI/CD short-lived STS tokens (15-60 min). No credentials to
rotate, audit, or accidentally expose. #1 AWS security best practice.
Ref: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

## Bootstrap State Backend
```bash
aws s3api create-bucket --bucket prod-enterprise-tfstate-ACCOUNT_ID --region us-east-1
aws s3api put-bucket-versioning --bucket prod-enterprise-tfstate-ACCOUNT_ID \
  --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-1
```

## Deploy Sequence
```bash
cd terraform/environments/dev
terraform init -backend-config="bucket=dev-enterprise-tfstate-ACCOUNT_ID"
terraform plan -var-file=dev.tfvars && terraform apply
# Repeat for staging, then prod (prod requires manual approval gate)
```

## Key References
- CIS EKS Benchmark: https://www.cisecurity.org/benchmark/kubernetes
- NIST 800-53 SC-7 (Boundary Protection): https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final
- AWS EKS Best Practices: https://aws.github.io/aws-eks-best-practices/
- HIPAA AWS Compliance: https://aws.amazon.com/compliance/hipaa-compliance/
