variable "subnet_ids" { type = list(string) }

variable "vpc_id" {type = string}

# variable "cluster_name" {
#   description = "The name of the EKS cluster"
#   type        = string
#   default     = "django-cluster"
# }