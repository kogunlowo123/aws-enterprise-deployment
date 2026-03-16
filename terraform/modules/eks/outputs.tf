output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster."
  value       = aws_eks_cluster.main.arn
}

output "cluster_security_group_id" {
  description = "The security group ID of the EKS cluster."
  value       = aws_security_group.cluster.id
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider for IRSA."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "The URL of the OIDC provider."
  value       = aws_iam_openid_connect_provider.eks.url
}
