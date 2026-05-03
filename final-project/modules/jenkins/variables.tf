variable "cluster_name"      { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "git_username" { type = string }

variable "git_token" {
  type      = string
  sensitive = true
}

variable "admin_password" {
  type      = string
  sensitive = true
}