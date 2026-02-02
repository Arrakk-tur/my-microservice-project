provider "aws" { region = "eu-north-1" }

# Отримуємо дані про поточного користувача
data "aws_caller_identity" "current" {}

# Підключаємо модуль S3 та DynamoDB
module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "s3-jviaospovjao39458n3949n3"
  table_name  = "terraform-locks"
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
  cicd_role_arn     = data.aws_caller_identity.current.arn # Твій поточний користувач
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