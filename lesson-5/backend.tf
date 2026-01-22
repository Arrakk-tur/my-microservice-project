# terraform {
#   backend "s3" {
#     bucket         = "s3-jviaospovjao39458n3949n3"
#     key            = "lesson-5/terraform.tfstate"
#     region         = "eu-north-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }