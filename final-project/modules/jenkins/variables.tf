variable "cluster_name"      { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "kubeconfig"        { type = string }

variable "admin_password" {
  type      = string
  sensitive = true
}