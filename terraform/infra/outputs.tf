# Sorties consommees par la couche "app" (memes noms que la couche "azure")

output "host" {
  description = "Adresse de l'API Kubernetes"
  value       = minikube_cluster.pfe.host
}

output "client_certificate" {
  value     = minikube_cluster.pfe.client_certificate
  sensitive = true
}

output "client_key" {
  value     = minikube_cluster.pfe.client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = minikube_cluster.pfe.cluster_ca_certificate
  sensitive = true
}

output "node_ip" {
  description = "IP du noeud control-plane (acces NodePort)"
  value       = regex("https?://([^:/]+)", minikube_cluster.pfe.host)[0]
}

output "service_type" {
  description = "Type de Service conseille pour exposer l'application"
  value       = "NodePort"
}
