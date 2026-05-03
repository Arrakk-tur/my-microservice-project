provider "aws" { region = "eu-north-1" }

# Отримуємо дані про поточного користувача
data "aws_caller_identity" "current" {}

# AWS Secrets Manager для паролів
resource "aws_secretsmanager_secret" "django_secrets" {
  name        = "django-app-secrets-v2"
  description = "Secrets for Django App"
}

resource "aws_secretsmanager_secret_version" "django_secrets_val" {
  secret_id     = aws_secretsmanager_secret.django_secrets.id
  secret_string = jsonencode({
    SECRET_KEY        = "django-insecure-975z@8)1!8b6vjiasofgua8sf9f8yeq9g8qhwoishjob"
    DATABASE_PASSWORD = "postgres_password"
  })
}

# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "s3-jviaospovjao39458n3949n3"
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
  availability_zones = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  vpc_name           = "lesson-5-vpc"
}

# Підключаємо модуль ECR
module "ecr" {
  source            = "./modules/ecr"
  ecr_name          = "lesson-7-ecr"
  scan_on_push      = true
  cicd_role_arn     = data.aws_caller_identity.current.arn
  workload_role_arn = module.eks.node_role_arn            # Вузли кластера
}

# Підключаємо модуль EKS
module "eks" {
  source     = "./modules/eks"
  subnet_ids = module.vpc.private_subnet_ids
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
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec {
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

# Розгортання Django
resource "helm_release" "django_app" {
  name       = "django-release"
  chart      = "./charts/django-app" # Шлях до чарту
  namespace  = "default"
  wait       = true
  timeout    = 600

  # Передаємо динамічні дані з Terraform у values.yaml
  set {
    name  = "image.repository"
    value = module.ecr.repository_url
  }

  set {
    name  = "image.tag"
    value = "latest"
  }

  depends_on = [
    module.eks,
    helm_release.metrics_server,
    module.ecr
  ]
}

# Встановлення Secrets Store CSI Driver
resource "helm_release" "secrets_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  set {
    name  = "syncSecret.enabled"
    value = "true"
  }
}

# Встановлення AWS Provider для драйвера
resource "helm_release" "aws_secrets_manager_provider" {
  name       = "aws-secrets-manager-provider"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
}

# Додаткові права для EKS Nodes (S3 + Secrets Manager)
resource "aws_iam_role_policy" "node_additional_perms" {
  name = "eks-node-additional-perms"
  role = module.eks.node_role_arn

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