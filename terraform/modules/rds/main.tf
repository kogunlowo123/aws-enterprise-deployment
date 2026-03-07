# Aurora PostgreSQL Multi-AZ — HIPAA Compliant
# Architect: Kehinde (Kenny) Samson Ogunlowo

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-aurora-subnet-group"
  subnet_ids = var.data_subnet_ids
  tags       = merge(var.common_tags, { Name = "${var.environment}-aurora-subnet-group" })
}

resource "aws_security_group" "aurora" {
  name_prefix = "${var.environment}-aurora-"
  vpc_id      = var.vpc_id
  description = "Aurora PostgreSQL security group - app tier only"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
    description     = "PostgreSQL from application tier only"
  }

  tags = merge(var.common_tags, { Name = "${var.environment}-aurora-sg", Compliance = "HIPAA-164.312-e" })
}

resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.environment}-aurora-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "15.4"
  database_name           = var.database_name
  master_username         = var.master_username
  manage_master_user_password = true   # AWS Secrets Manager rotation
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.aurora.id]
  storage_encrypted       = true
  kms_key_id              = var.kms_key_arn
  deletion_protection     = var.environment == "prod"
  skip_final_snapshot     = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.environment}-aurora-final-snapshot" : null
  backup_retention_period = var.environment == "prod" ? 35 : 7
  preferred_backup_window = "03:00-04:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  iam_database_authentication_enabled = true
  copy_tags_to_snapshot   = true

  tags = merge(var.common_tags, {
    Name       = "${var.environment}-aurora-cluster"
    Compliance = "HIPAA-164.312-a-2-iv"
    DataClass  = "PHI"
  })
}

resource "aws_rds_cluster_instance" "main" {
  count                = var.instance_count
  identifier           = "${var.environment}-aurora-${count.index}"
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = var.instance_class
  engine               = aws_rds_cluster.main.engine
  engine_version       = aws_rds_cluster.main.engine_version
  publicly_accessible  = false
  monitoring_interval  = 60
  monitoring_role_arn  = aws_iam_role.rds_enhanced_monitoring.arn
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_key_arn
  performance_insights_retention_period = 731  # 2 years

  tags = var.common_tags
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.environment}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "monitoring.rds.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

variable "environment" {}
variable "vpc_id" {}
variable "data_subnet_ids" { type = list(string) }
variable "app_security_group_id" {}
variable "kms_key_arn" {}
variable "database_name" { default = "enterprise_db" }
variable "master_username" { default = "dbadmin" }
variable "instance_count" { default = 2 }
variable "instance_class" { default = "db.r6g.large" }
variable "common_tags" { type = map(string); default = {} }
