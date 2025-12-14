resource "google_compute_global_address" "argocd_ip" {
  name    = "argocd-ip"
  project = local.project_id
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  values = [templatefile("${path.module}/values/argocd-values.yaml", {
    static_ip_name = google_compute_global_address.argocd_ip.name
    host           = local.argocd_host
  })]


  depends_on = [
    helm_release.external_secrets,
    google_compute_global_address.argocd_ip
  ]
}
