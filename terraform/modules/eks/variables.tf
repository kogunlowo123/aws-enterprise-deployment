variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption."
  type        = string
}

variable "enable_public_endpoint" {
  description = "Enable public API server endpoint."
  type        = bool
  default     = false
}

variable "allowed_public_cidrs" {
  description = "CIDR blocks allowed to access the public endpoint."
  type        = list(string)
  default     = []
}

variable "app_node_desired" {
  description = "Desired number of application node group instances."
  type        = number
  default     = 3
}

variable "app_node_min" {
  description = "Minimum number of application node group instances."
  type        = number
  default     = 3
}

variable "app_node_max" {
  description = "Maximum number of application node group instances."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
