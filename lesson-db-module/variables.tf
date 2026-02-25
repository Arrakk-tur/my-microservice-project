variable "aws_region" {
  type        = string
  default     = "eu-north-1"
}

variable "s3_bucket_name" {
  type        = string
  description     = "s3-jviaospovjao39458n3949n3"
}

variable "git_username" {
  type        = string
  description     = "GIT_USERNAME"
}

variable "git_repo" {
  type        = string
  description     = "https://github.com/git_username/your-monorepo.git"
}

variable "git_token" {
  type      = string
  sensitive = true
  # default прибрано для безпеки
}

variable "django_secret" {
  type        = string
  description     = "DJANGO_SECRET_KEY"
}

variable "django_db_pswd" {
  type        = string
  description     = "postgres_password"
}

variable "jenkins_admin_password" {
  type      = string
  sensitive = true
}