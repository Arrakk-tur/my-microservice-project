provider "aws" { region = var.aws_region }

# Отримуємо дані про поточного користувача
data "aws_caller_identity" "current" {}

# AWS Secrets Manager для паролів
resource "aws_secretsmanager_secret" "django_secrets" {
  name        = "django-app-secrets-v3"
  description = "Secrets for Django App"
}

resource "aws_secretsmanager_secret_version" "django_secrets_val" {
  secret_id = aws_secretsmanager_secret.django_secrets.id
  secret_string = jsonencode({
    SECRET_KEY        = var.django_secret
    DATABASE_PASSWORD = var.django_db_pswd
    DATABASE_HOST     = module.rds.db_endpoint
    DATABASE_PORT     = module.rds.db_port
    DATABASE_USER     = "postgres_user"
    DATABASE_NAME     = "my_best_db"
  })
}

resource "kubernetes_secret_v1" "argocd_repo_creds" {
  metadata {
    name      = "my-repo-creds"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.git_repo
    password = var.git_token
    username = var.git_username
  }
  depends_on = [module.argo_cd]
}

# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = var.s3_bucket_name
  table_name  = "terraform-locks"
}

# S3 Bucket для статичних файлів
resource "aws_s3_bucket" "static_assets" {
  bucket        = "my-django-static-assets-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

# Підключаємо модуль VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  vpc_name           = "fp-vpc"
}

# Підключаємо модуль ECR
module "ecr" {
  source            = "./modules/ecr"
  ecr_name          = "fp-ecr"
  scan_on_push      = true
  cicd_role_arn     = data.aws_caller_identity.current.arn
  workload_role_arn = module.eks.node_role_arn # Вузли кластера
}

# Підключаємо модуль EKS
module "eks" {
  source     = "./modules/eks"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}

# Підключаємо модуль Jenkins
module "jenkins" {
  source            = "./modules/jenkins"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  admin_password    = var.jenkins_admin_password
  git_username      = var.git_username
  git_token         = var.git_token
}

# Підключаємо модуль Argo_CD
module "argo_cd" {
  source         = "./modules/argo_cd"
  namespace      = "argocd"
  chart_version  = "5.46.4"
  git_repo       = var.git_repo
  s3_bucket_name = aws_s3_bucket.static_assets.id
  cluster_name   = module.eks.cluster_name
  aws_region     = var.aws_region
}

# Розгортання моніторингу Prometheus & Grafana
resource "kubernetes_namespace_v1" "monitoring" {
  metadata { name = "monitoring" }
}

resource "helm_release" "prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "65.2.0" # Стабільна версія

  # Вимикаємо дефолтні правила, якщо вузлів мало (економить ресурси t3.medium)
  set = [{
    name  = "defaultRules.create"
    value = "false"
  }]

  depends_on = [module.eks]
}

# Підключаємо модуль DB (Postgres)
module "rds" {
  source          = "./modules/rds"
  project_name    = "django-app"
  use_aurora      = false # Можна винести в variables.tf
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  eks_nodes_sg_id = module.eks.node_security_group_id

  db_name         = "my_best_db"
  username        = "postgres_user"
  password        = var.django_db_pswd
  engine_version  = "17.4"
  family          = "postgres17"
  instance_class  = "db.t3.medium"
  max_connections = "200"
}

# Налаштування провайдерів для роботи з K8s через Terraform
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# Встановлюємо Metrics Server
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  depends_on = [module.eks]
}

# Встановлення Secrets Store CSI Driver
resource "helm_release" "secrets_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  set = [{
    name  = "syncSecret.enabled"
    value = "true"
  }]
}

# Встановлення AWS Provider для драйвера
resource "helm_release" "aws_secrets_manager_provider" {
  name       = "aws-secrets-manager-provider"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"

  depends_on = [helm_release.secrets_csi_driver]
  set = [
    {
      name  = "secrets-store-csi-driver.install"
      value = "false"
    }
  ]
}

# Додаткові права для EKS Nodes (S3 + Secrets Manager)
resource "aws_iam_role_policy" "node_additional_perms" {
  name = "eks-node-additional-perms"
  role = module.eks.node_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = [aws_secretsmanager_secret.django_secrets.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObject"]
        Resource = ["${aws_s3_bucket.static_assets.arn}", "${aws_s3_bucket.static_assets.arn}/*"]
      }
    ]
  })
}