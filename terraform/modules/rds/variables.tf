variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Aurora will be created."
  type        = string
}

variable "data_subnet_ids" {
  description = "List of data-tier subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group ID of the application tier."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption."
  type        = string
}

variable "database_name" {
  description = "Name of the default database."
  type        = string
  default     = "enterprise_db"
}

variable "master_username" {
  description = "Master username for the database."
  type        = string
  default     = "dbadmin"
}

variable "instance_count" {
  description = "Number of Aurora cluster instances."
  type        = number
  default     = 2
}

variable "instance_class" {
  description = "Instance class for Aurora cluster instances."
  type        = string
  default     = "db.r6g.large"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
