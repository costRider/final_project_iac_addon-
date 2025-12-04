###############################################
# envs/dev/main.tf
#
# - S3 backend (이 레포용 state)
# - 기존 EKS env tfstate remote_state
# - aws_eks_cluster / aws_eks_cluster_auth
# - kubernetes / helm provider
# - locals (cluster_name, vpc_id 등)
###############################################

terraform {
  required_version = "= 1.14.0"

  backend "s3" {
    bucket       = "final-terraform-s3"
    key          = "aws/dev/mgmt/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

###############################################
# 1) AWS Provider (mgmt EC2 IAM Role 사용)
###############################################
provider "aws" {
  region = var.region
  default_tags {
    tags = local.common_tags
  }
}

###############################################
# 2) 기존 EKS env tfstate 가져오기
###############################################
data "terraform_remote_state" "eks_env" {
  backend = "s3"

  config = {
    bucket       = var.tfstate_bucket
    key          = var.tfstate_key_eks_env
    region       = var.region
    use_lockfile = true
  }
}

###############################################
# 3) EKS 정보 / 인증 토큰
###############################################
data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.eks_env.outputs.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.eks_env.outputs.eks_cluster_name
}

###############################################
# 4) Providers: Kubernetes / Helm
###############################################
provider "kubernetes" {
  host = data.aws_eks_cluster.this.endpoint

  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.this.certificate_authority[0].data
  )

  token = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.this.endpoint

    cluster_ca_certificate = base64decode(
      data.aws_eks_cluster.this.certificate_authority[0].data
    )

    token = data.aws_eks_cluster_auth.this.token
  }
}

###############################################
# 5) 공통 locals
###############################################
locals {
  external_secrets_role_arn = data.terraform_remote_state.eks_env.outputs.external_secrets_role_arn
  cluster_name              = data.terraform_remote_state.eks_env.outputs.eks_cluster_name
  vpc_id                    = data.terraform_remote_state.eks_env.outputs.vpc_id
  project_name              = data.terraform_remote_state.eks_env.outputs.project_name
  environment               = data.terraform_remote_state.eks_env.outputs.environment
  owner                     = data.terraform_remote_state.eks_env.outputs.owner
  cost_center               = data.terraform_remote_state.eks_env.outputs.cost_center

  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    Owner       = local.owner

    ManagedBy   = "Terraform"
    cost_center = local.cost_center
  }
}