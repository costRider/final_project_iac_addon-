terraform {
  backend "gcs" {
    bucket = "final-terraform-gcs"
    prefix = "gcp/addons/dev"
  }

  required_providers {
    google     = { source = "hashicorp/google", version = "~> 6.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.33" }
    helm       = { source = "hashicorp/helm", version = "~> 2.13" }
  }
}

############################################################
# Remote state: GCP Infra (cluster_name, region, gsa email)
############################################################
data "terraform_remote_state" "gcp_env" {
  backend = "gcs"
  config = {
    bucket = "final-terraform-gcs"
    prefix = "gcp/env/dev"
  }
}

locals {
  project_id    = data.terraform_remote_state.gcp_env.outputs.project_id
  region        = data.terraform_remote_state.gcp_env.outputs.region
  cluster_name  = data.terraform_remote_state.gcp_env.outputs.cluster_name
  eso_gsa_email = data.terraform_remote_state.gcp_env.outputs.gke_workload_sa_email
}

provider "google" {
  project = local.project_id
  region  = local.region
}

data "google_client_config" "default" {}

data "google_container_cluster" "this" {
  project  = local.project_id
  location = local.region
  name     = local.cluster_name
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.this.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.this.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
  }
}