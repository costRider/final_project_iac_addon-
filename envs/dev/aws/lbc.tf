###############################################
# envs/dev/lbc.tf
#
# AWS Load Balancer Controller (Helm)
# - Pod Identity용 SA는 기존 인프라에서 관리된다고 가정
# - 여기서는 해당 SA를 재사용
###############################################

# LBC IAM Policy
resource "aws_iam_policy" "lbc" {
  name        = "${local.project_name}-${local.environment}-AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam_policy_aws_load_balancer_controller.json")
}

# LBC IAM Role (Pod Identity용)
resource "aws_iam_role" "lbc" {
  name = "${local.project_name}-AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lbc_attach" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}

resource "aws_eks_pod_identity_association" "lbc" {
  cluster_name    = local.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.lbc.arn

  depends_on = [
    aws_iam_role_policy_attachment.lbc_attach,
  ]
}

resource "helm_release" "aws_load_balancer_controller" {
  name      = "aws-load-balancer-controller"
  namespace = "kube-system"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.lbc_chart_version

  create_namespace = false

  # Pod Identity 전제:
  # - SA 이름: aws-load-balancer-controller
  # - 네임스페이스: kube-system
  # - role_arn 매핑은 aws_eks_pod_identity_association 리소스에서 처리
  values = [
    yamlencode({
      clusterName = local.cluster_name
      region      = var.region
      vpcId       = local.vpc_id

      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
      }
    })
  ]

  depends_on = [
    aws_eks_pod_identity_association.lbc
  ]
}
