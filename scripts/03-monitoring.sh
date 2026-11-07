#!/usr/bin/env bash
# Installe Prometheus + Grafana (kube-prometheus-stack) via Helm
set -euo pipefail
cd "$(dirname "$0")/.."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f monitoring/values.yaml --wait --timeout 15m

kubectl -n monitoring get pods
echo
echo "Grafana    : http://$(minikube ip):30300   (admin / admin-pfe)"
echo "Prometheus : http://$(minikube ip):30090"
