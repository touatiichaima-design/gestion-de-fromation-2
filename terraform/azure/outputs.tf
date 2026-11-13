# Memes noms de sorties que la couche "infra" : la couche "app" fonctionne
# sans modification sur l'un ou l'autre cluster.

output "host" {
  value     = azurerm_kubernetes_cluster.pfe.kube_config[0].host
  sensitive = true
}

output "client_certificate" {
  value     = base64decode(azurerm_kubernetes_cluster.pfe.kube_config[0].client_certificate)
  sensitive = true
}

output "client_key" {
  value     = base64decode(azurerm_kubernetes_cluster.pfe.kube_config[0].client_key)
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = base64decode(azurerm_kubernetes_cluster.pfe.kube_config[0].cluster_ca_certificate)
  sensitive = true
}

output "node_ip" {
  value = ""
}

output "service_type" {
  description = "Sur AKS, un Service LoadBalancer obtient une IP publique Azure"
  value       = "LoadBalancer"
}
