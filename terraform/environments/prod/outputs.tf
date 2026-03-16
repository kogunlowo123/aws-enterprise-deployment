output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "List of private application subnet IDs."
  value       = module.vpc.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "List of private data subnet IDs."
  value       = module.vpc.private_data_subnet_ids
}
