# =====================================================================
#  Couche APP : deploiement de la plateforme dans le cluster
#  Le cluster cible est lu depuis l'etat Terraform de la couche infra
#  (local : ../infra, cloud : ../azure) -> meme code, autre cluster.
# =====================================================================

terraform {
  required_version = ">= 1.6"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.5"
    }
  }
}

data "terraform_remote_state" "cluster" {
  backend = "local"
  config = {
    path = var.cluster_state_path
  }
}

locals {
  cluster = data.terraform_remote_state.cluster.outputs
}

provider "kubernetes" {
  host                   = local.cluster.host
  client_certificate     = local.cluster.client_certificate
  client_key             = local.cluster.client_key
  cluster_ca_certificate = local.cluster.cluster_ca_certificate
}
