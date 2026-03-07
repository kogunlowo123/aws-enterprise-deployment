# Enterprise EKS Module - Production-Grade Kubernetes
# Architect: Kehinde (Kenny) Samson Ogunlowo
# CIS EKS Benchmark v1.4 hardened | IRSA enabled | Karpenter autoscaler

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.25" }
  }
}

# ── EKS Cluster ──────────────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.enable_public_endpoint
    public_access_cidrs     = var.enable_public_endpoint ? var.allowed_public_cidrs : []
    security_group_ids      = [aws_security_group.cluster.id]
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = [
    "api", "audit", "authenticator", "controllerManager", "scheduler"
  ]

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = "172.20.0.0/16"
  }

  tags = merge(var.common_tags, {
    Name       = var.cluster_name
    Compliance = "CIS-EKS-Benchmark-v1.4"
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.eks
  ]
}

# ── Node Groups ───────────────────────────────────────────────────
resource "aws_eks_node_group" "app" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-app-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["m5.xlarge", "m5.2xlarge"]
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = var.app_node_desired
    max_size     = var.app_node_max
    min_size     = var.app_node_min
  }

  update_config { max_unavailable = 1 }

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  labels = {
    role        = "application"
    environment = var.environment
  }

  taint {
    key    = "workload-type"
    value  = "application"
    effect = "NO_SCHEDULE"
  }

  tags = merge(var.common_tags, { NodeGroup = "application" })
  depends_on = [aws_iam_role_policy_attachment.node_policies]
}

resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-system-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t3.medium", "t3.large"]
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  update_config { max_unavailable = 1 }

  labels = { role = "system", environment = var.environment }
  tags   = merge(var.common_tags, { NodeGroup = "system" })

  depends_on = [aws_iam_role_policy_attachment.node_policies]
}

# ── Hardened Launch Template ──────────────────────────────────────
resource "aws_launch_template" "node" {
  name_prefix = "${var.cluster_name}-node-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 required (CIS 5.1.1)
    http_put_response_hop_limit = 1           # Prevent SSRF via metadata
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.common_tags, { Name = "${var.cluster_name}-node" })
  }
}

# ── EKS Add-ons ───────────────────────────────────────────────────
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  addon_version            = "v1.16.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn = aws_iam_role.vpc_cni.arn
  tags                     = var.common_tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "coredns"
  addon_version            = "v1.11.1-eksbuild.4"
  resolve_conflicts_on_create = "OVERWRITE"
  tags                     = var.common_tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "kube-proxy"
  addon_version            = "v1.29.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  tags                     = var.common_tags
}

resource "aws_eks_addon" "aws_ebs_csi" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.27.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
  tags                     = var.common_tags
}

# ── CloudWatch Log Group for EKS ─────────────────────────────────
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 90
  kms_key_id        = var.kms_key_arn
  tags              = var.common_tags
}

# ── IAM - Cluster Role ────────────────────────────────────────────
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "eks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ── IAM - Node Role ───────────────────────────────────────────────
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"  # Session Manager (no SSH)
  ])
  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# ── Security Group ────────────────────────────────────────────────
resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  vpc_id      = var.vpc_id
  description = "EKS cluster control plane security group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.common_tags, { Name = "${var.cluster_name}-cluster-sg" })
}

# ── IRSA - OIDC Provider ──────────────────────────────────────────
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  tags            = var.common_tags
}

# ── IRSA Roles (VPC CNI, EBS CSI) ───────────────────────────────
resource "aws_iam_role" "vpc_cni" {
  name = "${var.cluster_name}-vpc-cni-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-node"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role" "ebs_csi" {
  name = "${var.cluster_name}-ebs-csi-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
