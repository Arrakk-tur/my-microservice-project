variable "ecr_name" { type = string }
variable "scan_on_push"  { type = bool }
variable "cicd_role_arn" {
  description = "ARN ролі для CI/CD (Push/Pull)"
  type        = string
}

variable "workload_role_arn" {
  description = "ARN ролі для серверів/контейнерів (Only Pull)"
  type        = string
}