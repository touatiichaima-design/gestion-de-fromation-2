#!/usr/bin/env bash
# Installe kubectl, minikube et helm, puis démarre le cluster Minikube (driver Docker)
set -euo pipefail

echo "==> kubectl"
if ! command -v kubectl >/dev/null; then
  KVER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl"
  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
fi
kubectl version --client

echo "==> minikube"
if ! command -v minikube >/dev/null; then
  curl -fsSLo /tmp/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo install -m 0755 /tmp/minikube /usr/local/bin/minikube
fi
minikube version

echo "==> helm"
if ! command -v helm >/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
helm version --short

echo "==> Docker accessible sans sudo ?"
if ! docker info >/dev/null 2>&1; then
  sudo usermod -aG docker "$USER"
  echo "!! Utilisateur ajouté au groupe docker : reconnectez-vous puis relancez ce script."
  exit 1
fi

echo "==> Démarrage de Minikube"
if ! minikube status >/dev/null 2>&1; then
  # 3500 Mo : en dessous, l'API server + Prometheus + Grafana font swapper la VM
  minikube start --driver=docker --memory=3500 --cpus=2
fi
minikube addons enable metrics-server   # requis par l'HPA (auto-scaling)

kubectl get nodes -o wide
