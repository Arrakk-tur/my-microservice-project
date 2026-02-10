output "cluster_endpoint" { value = aws_eks_cluster.main.endpoint }
output "cluster_ca_certificate" { value = aws_eks_cluster.main.certificate_authority[0].data }
output "cluster_name" { value = aws_eks_cluster.main.name }
output "node_role_arn" { value = aws_iam_role.node_group.arn }