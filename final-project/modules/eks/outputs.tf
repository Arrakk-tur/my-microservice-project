output "cluster_endpoint" { value = aws_eks_cluster.main.endpoint }
output "cluster_ca_certificate" { value = aws_eks_cluster.main.certificate_authority[0].data }
output "cluster_name" { value = aws_eks_cluster.main.name }
output "node_role_arn" { value = aws_iam_role.node_group.arn }

output "oidc_provider_arn" { value = aws_iam_openid_connect_provider.eks.arn }
output "oidc_provider_url" { value = aws_eks_cluster.main.identity[0].oidc[0].issuer }

output "node_security_group_id" {
  description = "Security Group ID of the EKS nodes"
  value       = aws_security_group.eks_nodes_sg.id
}

output "node_role_name" {
  description = "Name of the node IAM role"
  value       = aws_iam_role.node_group.name
}