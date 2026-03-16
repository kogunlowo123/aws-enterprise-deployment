variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region for VPC endpoint service names."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "EKS cluster name for subnet tagging."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
