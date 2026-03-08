# IAM роль для EBS CSI Driver
resource "aws_iam_role" "ebs_csi_irsa_role" {
  name = "${aws_eks_cluster.main.name}-ebs-csi-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

# Прикріплюємо офіційну політику до цієї ролі
resource "aws_iam_role_policy_attachment" "ebs_irsa_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_irsa_role.name
}

# EKS Addon з привʼязаною IRSA IAM роллю
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                  = aws_eks_cluster.main.name
  addon_name                    = "aws-ebs-csi-driver"
  addon_version                 = "v1.41.0-eksbuild.1"
  service_account_role_arn      = aws_iam_role.ebs_csi_irsa_role.arn
  resolve_conflicts_on_update  = "PRESERVE"

  depends_on = [
    aws_iam_role_policy_attachment.ebs_irsa_policy
  ]
}
