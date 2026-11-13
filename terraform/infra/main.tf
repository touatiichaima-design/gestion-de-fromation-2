# =====================================================================
#  Couche INFRA : cluster Kubernetes multi-noeuds (cloud prive local)
#  Equivalent local d'un cluster manage AKS / EKS / GKE.
#  terraform init && terraform apply
# =====================================================================

terraform {
  required_version = ">= 1.6"
  required_providers {
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = "~> 0.8.0"
    }
  }
}

provider "minikube" {
  kubernetes_version = var.kubernetes_version
}

resource "minikube_cluster" "pfe" {
  cluster_name      = var.cluster_name
  driver            = "docker"
  nodes             = var.node_count # 1 noeud control-plane + (node_count - 1) workers
  cpus              = var.cpus_per_node
  memory            = var.memory_per_node
  base_image        = var.base_image # image de noeud deja presente : pas de re-telechargement
  container_runtime = "containerd"   # runtime standard de Kubernetes (images pre-chargees en cache)
  # Reseau overlay VXLAN : le trafic pod-a-pod entre noeuds est encapsule.
  # (kindnet route les IP de pods en clair, ce que le pare-feu de Docker 29 bloque)
  cni = "flannel"

  addons = [
    "default-storageclass",
    "storage-provisioner",
    "metrics-server", # requis par l'HorizontalPodAutoscaler
  ]
}

# Correctif reseau : le provider laisse actif le CNI "podman bridge" (10.244.0.0/16)
# a cote de Flannel. Les pods du control-plane s'y raccordent et deviennent
# injoignables depuis les autres noeuds. On le desactive puis on recree CoreDNS.
resource "terraform_data" "cni_fix" {
  triggers_replace = [minikube_cluster.pfe.id]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      set -e
      kubectl --context ${var.cluster_name} -n kube-flannel rollout status ds/kube-flannel-ds --timeout=300s
      for n in $(kubectl --context ${var.cluster_name} get nodes -o jsonpath='{.items[*].metadata.name}'); do
        minikube -p ${var.cluster_name} ssh -n $n -- "sudo sh -c 'for f in /etc/cni/net.d/*podman*.conflist; do [ -f \$f ] && mv \$f \$f.disabled; done; ip link delete cni-podman0 2>/dev/null || true'" </dev/null
      done
      kubectl --context ${var.cluster_name} -n kube-system rollout restart deploy/coredns deploy/metrics-server
      kubectl --context ${var.cluster_name} -n kube-system rollout status deploy/coredns --timeout=180s
      kubectl --context ${var.cluster_name} -n kube-system rollout status deploy/metrics-server --timeout=180s
    EOT
  }
}

# Pre-chargement des images dans les noeuds (evite de les retelecharger
# depuis Docker Hub avec une connexion lente)
resource "terraform_data" "images" {
  triggers_replace = [minikube_cluster.pfe.id, join(",", var.preload_images)]

  provisioner "local-exec" {
    command = join(" && ", [for img in var.preload_images :
    "docker image inspect ${img} >/dev/null 2>&1 && minikube -p ${var.cluster_name} image load ${img} || echo 'image ${img} absente localement : elle sera telechargee'"])
  }
}
