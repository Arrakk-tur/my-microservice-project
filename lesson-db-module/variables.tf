variable "aws_region" {
  type        = string
  default     = "eu-north-1"
}

variable "s3_bucket_name" {
  type        = string
  description     = "S3 Bucket name"
}

variable "git_username" {
  type        = string
  description     = "логін на GitHub "
}

variable "git_repo" {
  type        = string
  description     = "URL Git репозиторію"
}

variable "git_token" {
  type      = string
  sensitive = true
  description = "GitHub Personal Access Token (PAT) з правами на читання/запис репозиторію."
  # default прибрано для безпеки
}

variable "django_secret" {
  type        = string
  description     = "DJANGO_SECRET_KEY"
}

variable "django_db_pswd" {
  type        = string
  description     = "Пароль для підключення до створеної бази даних"
}

variable "jenkins_admin_password" {
  type      = string
  sensitive = true
  description = "Бажаний пароль для доступу до веб-інтерфейсу Jenkins."
}