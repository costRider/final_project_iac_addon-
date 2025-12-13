resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  values = [yamlencode({
    server = {
      extraArgs = ["--insecure"]
      service   = { type = "ClusterIP" }
      ingress = {
        enabled          = true
        ingressClassName = "gce"
        annotations = {
          "kubernetes.io/ingress.class" = "gce"
        }

        # 도메인 없으면 임시 host로 두고, LB IP 뜬 다음 테스트해도 됨
        hosts    = [var.argocd_host]
        paths    = ["/"]
        pathType = "Prefix"
      }
    }
  })]

  depends_on = [helm_release.external_secrets] # 운영상 편의: ESO 먼저
}

variable "argocd_host" {
  type    = string
  default = "argocd.example.local"
}