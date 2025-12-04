# mgmt/env/dev/external-secrets.tf 

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true

  # CRD 자동 설치
  set {
    name  = "installCRDs"
    value = "true"
  }

  # ServiceAccount 생성 + 이름 지정
  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }

  # IRSA Role 붙이기 (여기가 핵심)
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = local.external_secrets_role_arn
  }
}
