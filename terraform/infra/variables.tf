variable "cluster_name" {
  description = "Nom du cluster (profil Minikube)"
  type        = string
  default     = "pfe-iac"
}

variable "node_count" {
  description = "Nombre de noeuds du cluster (control-plane + workers)"
  type        = number
  default     = 2
  validation {
    condition     = var.node_count >= 2
    error_message = "Un cluster multi-noeuds necessite au moins 2 noeuds."
  }
}

variable "cpus_per_node" {
  description = "vCPU par noeud"
  type        = number
  default     = 2
}

variable "memory_per_node" {
  description = "Memoire par noeud (adapte a une VM de 5 Go)"
  type        = string
  default     = "1800mb"
}

variable "kubernetes_version" {
  description = "Version de Kubernetes"
  type        = string
  default     = "v1.37.0"
}

variable "base_image" {
  description = "Image des noeuds Kubernetes (driver docker)"
  type        = string
  default     = "gcr.io/k8s-minikube/kicbase:v0.0.51"
}

variable "preload_images" {
  description = "Images Docker a charger dans les noeuds"
  type        = list(string)
  default     = ["chaimatouati/gestion-formation:latest", "postgres:15"]
}
