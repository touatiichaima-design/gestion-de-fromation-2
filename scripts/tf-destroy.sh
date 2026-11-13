#!/usr/bin/env bash
# Detruit l'infrastructure creee par Terraform (application puis cluster).
set -euo pipefail
cd "$(dirname "$0")/.."
export TF_VAR_secret_key=x TF_VAR_postgres_password=x   # valeurs non utilisees pour detruire

terraform -chdir=terraform/app destroy -input=false -auto-approve || true
terraform -chdir=terraform/infra destroy -input=false -auto-approve

echo ">> Pour relancer le cluster principal : minikube start"
