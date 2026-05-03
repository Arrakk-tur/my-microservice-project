output "s3_bucket_arn" {
  description = "ARN бакета для стейт-файлів"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_name" {
  description = "Назва бакета"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  description = "Назва таблиці DynamoDB для блокувань"
  value       = aws_dynamodb_table.terraform_locks.name
}