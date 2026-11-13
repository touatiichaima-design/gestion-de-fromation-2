# =====================================================================
#  Couche AZURE : meme role que la couche "infra", sur le cloud public
#  Cluster manage AKS multi-noeuds avec auto-scaling des NOEUDS.
#
#  Non applique dans le cadre du PFE (pas de souscription Azure for
#  Students disponible pour l'etablissement). Pour l'utiliser :
#    az login
#    terraform -chdir=terraform/azure init && terraform -chdir=terraform/azure apply
#    terraform -chdir=terraform/app apply -var cluster_state_path=../azure/terraform.tfstate
# =====================================================================

terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.14"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "pfe" {
  name     = "rg-${var.project}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_kubernetes_cluster" "pfe" {
  name                = "aks-${var.project}"
  location            = azurerm_resource_group.pfe.location
  resource_group_name = azurerm_resource_group.pfe.name
  dns_prefix          = var.project
  sku_tier            = "Free"
  tags                = local.tags

  default_node_pool {
    name                 = "system"
    vm_size              = var.vm_size
    auto_scaling_enabled = true # Cluster Autoscaler : ajoute/retire des VM selon la charge
    min_count            = var.min_nodes
    max_count            = var.max_nodes
    os_disk_size_gb      = 30
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }
}

locals {
  tags = { project = var.project, environment = "pfe", managed-by = "terraform" }
}
