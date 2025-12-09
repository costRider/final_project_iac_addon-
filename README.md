# EKS Management Core (LBC + ArgoCD)

이 레포는 **기존 EKS 인프라(tfstate)** 를 기반으로\
mgmt EC2에서 Terraform + Helm으로 다음 컴포넌트를 관리하기 위한 목적의
프로젝트입니다.

-   AWS Load Balancer Controller (LBC)
-   ArgoCD
[![Build Status](https://github.com/costRider/final_project_iac_addon-/actions/workflows/eks-mgmt-addons.yaml/badge.svg)](https://github.com/costRider/final_project_iac_addon-/actions/workflows/eks-mgmt-addons.yml)

------------------------------------------------------------------------

## 📌 레포 구조 (Repository Tree)

    eks-mgmt-core/
    ├─ README.md
    └─ envs/
       └─ dev/
          ├─ main.tf          # backend, remote_state, providers, locals
          ├─ variables.tf     # 공통 변수 정의
          ├─ lbc.tf           # AWS Load Balancer Controller (helm_release)
          ├─ argocd.tf        # ArgoCD (namespace + helm_release)
          └─ values/
             └─ argocd-values.yaml

환경(dev/stg/prd)을 늘리고 싶다면\
`envs/dev` 디렉터리를 복사해 값만 수정하면 됩니다.

------------------------------------------------------------------------

## 🧱 전제 조건 (Prerequisites)

본 레포는 "메인 인프라 Terraform"에서 이미 구축된 환경을 기반으로
동작합니다.

### 1. 다음 인프라가 기존 Terraform Root에서 구성되어 있어야 합니다.

-   VPC / Subnets\
-   EKS Cluster\
-   EKS Pod Identity Agent Addon\
-   LBC IAM Role & Pod Identity Association

예시:

``` hcl
resource "aws_eks_pod_identity_association" "lbc" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = var.lbc_role_arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_eks_cluster.this
  ]
}
```

------------------------------------------------------------------------

### 2. 메인 인프라 tfstate에 필요한 output

아래 값은 remote_state 읽기에 반드시 필요합니다.

``` hcl
output "eks_cluster_name" {
  value = aws_eks_cluster.this.name
}

output "vpc_id" {
  value = aws_vpc.this.id
}
```

------------------------------------------------------------------------

### 3. 메인 인프라 tfstate는 S3 backend에 저장 중이어야 합니다.

예시 backend:

``` hcl
bucket         = "finalproj-tfstate-k8s"
key            = "aws/eks-iac/envs/dev/terraform.tfstate"
dynamodb_table = "finalproj-tfstate-lock"
region         = "ap-northeast-2"
```

------------------------------------------------------------------------

### 4. mgmt EC2 IAM Role 권한 요구사항

-   EKS API (DescribeCluster, AccessKubernetesApi 등)
-   S3 (tfstate bucket Get/Put/List)
-   DynamoDB (Lock table Get/Put/Update/Delete)

------------------------------------------------------------------------

## 🚀 사용 방법 (dev 환경 기준)

### mgmt EC2 내부에서 실행

``` bash
cd /mnt
git clone https://github.com/<your-account>/eks-mgmt-core.git
cd eks-mgmt-core/envs/dev

terraform init
terraform plan
terraform apply
```

------------------------------------------------------------------------

## 🔍 적용 후 검증

### LBC 확인

``` bash
kubectl get pods -n kube-system | grep aws-load-balancer-controller
```

### ArgoCD 확인

``` bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

------------------------------------------------------------------------

## 📘 License

MIT (원하는 방식으로 자유롭게 사용 가능)
