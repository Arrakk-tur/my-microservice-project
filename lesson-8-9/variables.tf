variable "aws_region" {
  type        = string
  default     = "eu-north-1"
}

variable "s3_bucket_name" {
  type        = string
  default     = "s3-jviaospovjao39458n3949n3"
}

variable "git_username" {
  type        = string
  default     = "GIT_USERNAME"
}

variable "git_repo" {
  type        = string
  default     = "https://github.com/git_username/your-monorepo.git"
}

variable "git_token" {
  type        = string
  default     = "YOUR_GITHUB_TOKEN"
}

variable "django_secret" {
  type        = string
  default     = "DJANGO_SECRET_KEY"
}

variable "django_db_pswd" {
  type        = string
  default     = "postgres_password"
}