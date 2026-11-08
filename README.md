# Plateforme de gestion des formations - PFE DevOps

[![CI/CD Pipeline](https://github.com/touatiichaima-design/gestion-de-fromation-2/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/touatiichaima-design/gestion-de-fromation-2/actions/workflows/ci-cd.yml)

Projet de fin d'études : **conception, conteneurisation et déploiement d'une plateforme de gestion des formations basée sur une architecture DevOps**.

La plateforme gère les formations, les formateurs, les participants, les inscriptions, les profils et les notifications.

## Stack technique

| Domaine | Outils |
|---|---|
| Application | Django 5.2 LTS (Python 3.12), PostgreSQL 15, Bootstrap |
| Conteneurisation | Docker, Docker Compose, Docker Hub |
| CI/CD | GitHub Actions (build, scan Trivy, publication) |
| Orchestration | Kubernetes (Minikube), Helm |
| Supervision | Prometheus, Grafana (kube-prometheus-stack) |
| Sécurité | Trivy, GitHub Code Scanning, secrets GitHub et Kubernetes |

## Organisation du dépôt

| Dossier | Contenu |
|---|---|
| `base/`, `gestion_formation/`, `templates/`, `static/` | Application Django |
| `k8s/` | Manifestes Kubernetes (namespace, ConfigMap, PVC, PostgreSQL, web) |
| `monitoring/` | Valeurs Helm de Prometheus et Grafana |
| `scripts/` | Installation des outils, déploiement, monitoring, exposition |
| `.github/workflows/` | Pipeline CI/CD |
| `docs/scrum/` | Méthodologie Scrum et Product Backlog |

## Démarrage rapide

```bash
# Environnement local (Docker Compose)
docker compose up -d

# Cluster Kubernetes (Minikube)
./scripts/01-install-tools.sh
./scripts/02-deploy-app.sh
./scripts/03-monitoring.sh
```

## Gestion de projet : Scrum

Le projet est piloté en **Scrum**, avec 6 sprints de 2 semaines.
- Méthodologie (rôles, cérémonies, Definition of Done) : [docs/scrum/SCRUM.md](docs/scrum/SCRUM.md)
- Product Backlog : les [issues](https://github.com/touatiichaima-design/gestion-de-fromation-2/issues?q=is%3Aissue)
- Sprints : les [milestones](https://github.com/touatiichaima-design/gestion-de-fromation-2/milestones?state=all)
- Tableau Scrum : [GitHub Projects](https://github.com/users/touatiichaima-design/projects/1)
