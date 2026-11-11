#!/usr/bin/env bash
# Déploie la plateforme sur Minikube. À lancer depuis la racine du projet (là où se trouve .env).
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-configmap.yaml

# Secret créé à partir du .env (jamais commité dans Git)
[ -f .env ] || { echo ".env introuvable"; exit 1; }
get() { grep -E "^$1=" .env | head -1 | cut -d= -f2- ; }
kubectl -n formation create secret generic formation-secret \
  --from-literal=SECRET_KEY="$(get SECRET_KEY)" \
  --from-literal=POSTGRES_USER="$(get POSTGRES_USER)" \
  --from-literal=POSTGRES_PASSWORD="$(get POSTGRES_PASSWORD)" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f k8s/02-pvc.yaml
kubectl apply -f k8s/03-postgres.yaml
kubectl -n formation rollout status deploy/postgres --timeout=300s
kubectl apply -f k8s/04-web.yaml
kubectl -n formation rollout status deploy/web --timeout=600s
kubectl apply -f k8s/05-hpa.yaml

kubectl -n formation get all,pvc
echo
echo "Application : http://$(minikube ip):30080"
