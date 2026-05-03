output "vpc_id" {
  description = "ID створеної VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Список ID публічних підмереж"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Список ID приватних підмереж"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ip" {
  description = "Публічна IP-адреса NAT Gateway"
  value       = aws_eip.nat.public_ip
}