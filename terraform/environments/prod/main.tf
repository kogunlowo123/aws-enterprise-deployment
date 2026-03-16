terraform {
  backend "s3" {
    bucket         = "prod-enterprise-tfstate"
    key            = "prod/aws-enterprise/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    kms_key_id     = "alias/prod-phi-encryption"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = "prod"
      ManagedBy   = "terraform"
      Owner       = "Kenny-Ogunlowo"
      CostCenter  = "cloud-platform"
      Compliance  = "HIPAA-CMMC-NIST"
      DataClass   = "Sensitive"
      Project     = "aws-enterprise-deployment"
    }
  }
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source       = "../../modules/vpc"
  environment  = "prod"
  aws_region   = var.aws_region
  vpc_cidr     = "10.0.0.0/16"
  cluster_name = var.cluster_name
  tags         = var.tags
}

module "security" {
  source              = "../../modules/security"
  environment         = "prod"
  aws_region          = var.aws_region
  account_id          = data.aws_caller_identity.current.account_id
  data_classification = "PHI-Sensitive"
  tags                = var.tags
}

module "eks" {
  source                 = "../../modules/eks"
  cluster_name           = var.cluster_name
  environment            = "prod"
  kubernetes_version     = "1.29"
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_app_subnet_ids
  kms_key_arn            = module.security.kms_key_arn
  enable_public_endpoint = false
  app_node_desired       = 3
  app_node_min           = 3
  app_node_max           = 10
  tags                   = var.tags
}
