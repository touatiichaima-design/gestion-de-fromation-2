# Infrastructure as Code (Terraform)

Toute l'infrastructure de la plateforme est décrite en code et créée par Terraform, en **deux couches indépendantes**, comme dans un projet cloud réel.

```
terraform/
├── infra/   Couche INFRA locale : cluster Kubernetes multi-nœuds (Minikube, driver Docker)
├── azure/   Couche INFRA cloud  : cluster AKS managé avec auto-scaling des nœuds (prêt, non appliqué)
└── app/     Couche APP          : namespace, ConfigMap, Secret, PVC, PostgreSQL, Django, Service, HPA
```

La couche `app` lit les informations de connexion au cluster dans l'état Terraform de la couche infra (`terraform_remote_state`). Les deux couches infra exposent **les mêmes sorties** (`host`, certificats, `service_type`) : **le même code applicatif se déploie en local ou sur Azure**.

| | Local (`infra/`) | Cloud (`azure/`) |
|---|---|---|
| Cluster | Minikube, 2 nœuds (Docker) | AKS, 2 à 4 nœuds Standard_B2s |
| Scaling des nœuds | Manuel (`node_count`) | Automatique (Cluster Autoscaler) |
| Exposition | Service NodePort 30080 | Service LoadBalancer (IP publique) |
| Stockage PostgreSQL | hostPath (nœud control-plane) | Azure Disk (StorageClass managée) |
| Coût | 0 € | ~0,04 €/h par nœud B2s |

## Utilisation

```bash
./scripts/tf-apply.sh      # crée le cluster puis déploie l'application (~10 min)
./scripts/tf-destroy.sh    # détruit tout (application puis cluster)
```

Les secrets (SECRET_KEY, mot de passe PostgreSQL) sont lus dans `.env` et transmis en variables `TF_VAR_*`. Ils n'apparaissent jamais dans le code. L'état Terraform (`*.tfstate`), qui les contient, est exclu de Git.

## Déploiement sur Azure (si une souscription est disponible)

```bash
az login
terraform -chdir=terraform/azure init
terraform -chdir=terraform/azure apply
terraform -chdir=terraform/app init
terraform -chdir=terraform/app apply -var cluster_state_path=../azure/terraform.tfstate
terraform -chdir=terraform/azure destroy    # pour ne pas consommer de crédit
```
