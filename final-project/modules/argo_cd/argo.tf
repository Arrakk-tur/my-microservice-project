resource "helm_release" "argo_cd" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  values = [
    file("${path.module}/values.yaml")
  ]

  create_namespace = true
}

# Скрипт перевірки готовності CRD
resource "null_resource" "wait_for_argo_crds" {
  depends_on = [helm_release.argo_cd]

  provisioner "local-exec" {
    command = <<EOT
      aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}
      echo "Очікування реєстрації Application CRD..."
      kubectl wait --for condition=established --timeout=120s crd/applications.argoproj.io
    EOT
  }
}

resource "helm_release" "argo_apps" {
  name       = "${var.name}-apps"
  chart      = "${path.module}/charts"
  namespace  = var.namespace
  create_namespace = true

  set = [
    {
      name  = "repoURL"
      value = var.git_repo
    },
    {
      name  = "s3BucketName"
      value = var.s3_bucket_name
    }
  ]
  depends_on = [null_resource.wait_for_argo_crds]
}