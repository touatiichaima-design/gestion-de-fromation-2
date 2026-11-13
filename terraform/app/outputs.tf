output "application_url" {
  description = "URL de l'application"
  value = (local.cluster.service_type == "NodePort"
    ? "http://${local.cluster.node_ip}:${var.node_port}"
  : "Adresse IP publique : kubectl get svc web -n ${var.namespace}")
}

output "namespace" {
  value = kubernetes_namespace_v1.app.metadata[0].name
}

output "image" {
  value = var.image
}
