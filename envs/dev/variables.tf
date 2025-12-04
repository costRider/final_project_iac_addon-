###############################################
# envs/dev/variables.tf
###############################################

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "tfstate_bucket" {
  description = "S3 bucket name where main EKS env terraform.tfstate is stored"
  type        = string
  default     = "final-terraform-s3"
}

variable "tfstate_key_eks_env" {
  description = "Key of the EKS env terraform.tfstate in the S3 bucket"
  type        = string
  default     = "aws/env/dev/terraform.tfstate"
}

# ArgoCD namespace
variable "argocd_namespace" {
  description = "Namespace where ArgoCD will be installed"
  type        = string
  default     = "argocd"
}

# ArgoCD Helm chart version
variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.7.21"
}

# LBC Helm chart version (optional)
variable "lbc_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
  default     = "1.9.1"
}
