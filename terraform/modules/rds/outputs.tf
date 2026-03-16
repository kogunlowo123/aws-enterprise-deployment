output "cluster_endpoint" {
  description = "The cluster endpoint for write operations."
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "The cluster reader endpoint for read operations."
  value       = aws_rds_cluster.main.reader_endpoint
}

output "cluster_id" {
  description = "The ID of the Aurora cluster."
  value       = aws_rds_cluster.main.id
}

output "security_group_id" {
  description = "The security group ID of the Aurora cluster."
  value       = aws_security_group.aurora.id
}
