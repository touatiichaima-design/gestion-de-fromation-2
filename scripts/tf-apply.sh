#!/usr/bin/env bash
# Cree toute l'infrastructure avec Terraform : cluster multi-noeuds puis application.
# Les secrets sont lus dans .env et passes en variables TF_VAR_* (jamais dans le code).
set -euo pipefail
cd "$(dirname "$0")/.."

get() { grep -E "^$1=" .env | head -1 | cut -d= -f2- ; }
export TF_VAR_secret_key="$(get SECRET_KEY)"
export TF_VAR_postgres_user="$(get POSTGRES_USER)"
export TF_VAR_postgres_password="$(get POSTGRES_PASSWORD)"
export TF_VAR_postgres_db="$(get POSTGRES_DB)"

# La VM (5 Go) ne peut pas faire tourner deux clusters a la fois
if minikube -p minikube status >/dev/null 2>&1; then
  echo ">> Arret temporaire du cluster 'minikube' pour liberer la memoire"
  minikube -p minikube stop
fi

# Le provider minikube telecharge l'ISO des drivers VM (~400 Mo) meme avec le
# driver docker, qui ne l'utilise pas : un fichier vide dans le cache l'en dispense.
ISO=~/.minikube/cache/iso/amd64/minikube-v1.39.0-amd64.iso
[ -s "$ISO" ] || { mkdir -p "$(dirname "$ISO")"; : > "$ISO"; }

echo "==> 1/2 Couche infra : cluster Kubernetes multi-noeuds"
terraform -chdir=terraform/infra init -input=false
terraform -chdir=terraform/infra apply -input=false -auto-approve

echo "==> 2/2 Couche app : deploiement de la plateforme"
terraform -chdir=terraform/app init -input=false
terraform -chdir=terraform/app apply -input=false -auto-approve

terraform -chdir=terraform/app output
