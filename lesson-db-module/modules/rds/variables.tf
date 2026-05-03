variable "project_name" { type = string }
variable "use_aurora" {
  type    = bool
  default = false
}

variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "eks_nodes_sg_id" { type = string }

variable "engine_version" {
  type    = string
  default = "13.7"
}

variable "family" {
  type    = string
  default = "postgres13"
}

variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_name" { type = string }
variable "username" { type = string }
variable "password" { type = string }

# Налаштування параметрів БД
variable "max_connections" {
  type    = string
  default = "100"
}

variable "work_mem" {
  type    = string
  default = "16MB"
}