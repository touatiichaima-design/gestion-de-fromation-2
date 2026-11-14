#!/usr/bin/env bash
# Cree une autorite de certification (CA) du PFE et un certificat HTTPS signe pour
# formation.pfe.local et grafana.pfe.local, puis les Secrets TLS Kubernetes.
# Les cles privees restent dans ~/pfe-tls (jamais dans Git).
# En production (domaine public) : cert-manager + Let's Encrypt.
set -euo pipefail
D=~/pfe-tls; mkdir -p "$D"; cd "$D"
HOSTS="formation.pfe.local grafana.pfe.local"

if [ ! -f ca.key ]; then
  openssl genrsa -out ca.key 4096 2>/dev/null
  openssl req -x509 -new -key ca.key -sha256 -days 825 -out ca.crt \
    -subj "/C=TN/O=PFE Gestion des formations/CN=PFE Gestion Formation - Autorite de certification"
fi

SAN=$(for h in $HOSTS; do printf "DNS:%s," "$h"; done | sed 's/,$//')
openssl genrsa -out tls.key 2048 2>/dev/null
openssl req -new -key tls.key -out tls.csr -subj "/C=TN/O=PFE Gestion des formations/CN=formation.pfe.local"
printf "subjectAltName=%s\nextendedKeyUsage=serverAuth\nkeyUsage=digitalSignature,keyEncipherment\n" "$SAN" > ext.cnf
openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tls.crt -days 397 -sha256 -extfile ext.cnf 2>/dev/null
chmod 600 ca.key tls.key

for ns in formation monitoring; do
  kubectl -n $ns create secret tls pfe-tls --cert=tls.crt --key=tls.key --dry-run=client -o yaml | kubectl apply -f -
done
openssl x509 -in tls.crt -noout -subject -issuer -enddate -ext subjectAltName
echo "Certificat de la CA a importer dans Windows : $D/ca.crt"
