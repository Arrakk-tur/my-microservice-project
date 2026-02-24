# Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids
}

# Security Group
resource "aws_security_group" "db_sg" {
  name   = "${var.project_name}-db-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_nodes_sg_id]
  }
}

# Parameter Group для RDS
resource "aws_db_parameter_group" "rds_pg" {
  count  = var.use_aurora ? 0 : 1
  name   = "${var.project_name}-rds-pg"
  family = var.family

  parameter {
    name  = "max_connections"
    value = var.max_connections
  }

  parameter {
    name  = "work_mem"
    value = var.work_mem
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }
}

# Parameter Group для Aurora
resource "aws_rds_cluster_parameter_group" "aurora_pg" {
  count  = var.use_aurora ? 1 : 0
  name   = "${var.project_name}-aurora-pg"
  family = var.family

  parameter {
    name  = "max_connections"
    value = var.max_connections
  }

  parameter {
    name  = "work_mem"
    value = var.work_mem
  }
}