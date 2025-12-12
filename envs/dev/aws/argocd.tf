###############################################
# envs/dev/argocd.tf
#
# - Namespace 생성
# - ArgoCD Helm Release
# - 초기 비밀번호 가져오기
# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
#
###############################################

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace

    labels = {
      "app.kubernetes.io/name"     = "argocd"
      "app.kubernetes.io/part-of"  = "argocd"
      "argocd-instance-managed-by" = "terraform"
    }
  }
}

resource "helm_release" "argocd" {
  name      = "argocd"
  namespace = kubernetes_namespace.argocd.metadata[0].name

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  create_namespace = false

  values = [
    file("${path.module}/values/argocd-values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.argocd,
    helm_release.aws_load_balancer_controller
  ]
}