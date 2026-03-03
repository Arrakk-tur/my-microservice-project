variable "name" {
  description = "Назва Helm-релізу"
  type        = string
  default     = "argo-cd"
}

variable "namespace" {
  description = "K8s namespace для Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Версія Argo CD чарта"
  type        = string
  default     = "5.46.4"
}

variable "git_repo" {
  type        = string
  description = "Repository URL for Argo CD Applications"
}

variable "s3_bucket_name" {
  description = "Динамічне ім'я S3 бакета для статики Django"
  type        = string
}

variable "cluster_name" { type = string }
variable "aws_region" { type = string }