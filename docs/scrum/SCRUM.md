# Méthodologie Scrum du projet

Projet de fin d'études : **Conception, conteneurisation et déploiement d'une plateforme de gestion des formations basée sur une architecture DevOps**.

Le projet est piloté avec **Scrum**, adapté à une équipe d'une seule développeuse. Le suivi se fait dans **GitHub Projects** :
- chaque user story est une *issue* ;
- chaque sprint est un *milestone* ;
- l'avancement est suivi sur un tableau *Backlog → À faire → En cours → Terminé*.

## 1. Rôles

| Rôle Scrum | Personne | Responsabilités |
|---|---|---|
| **Product Owner** | Encadrant professionnel | Exprime le besoin, priorise le Product Backlog, valide les incréments lors des Sprint Reviews |
| **Scrum Master** | Chaima Touati | Garantit le respect du cadre Scrum, anime les cérémonies, lève les obstacles (ressources de la VM, accès, outils) |
| **Équipe de développement** | Chaima Touati | Conçoit, développe, teste et déploie l'incrément de chaque sprint |
| **Partie prenante** | Encadrant académique | Suit l'avancement et évalue la démarche d'ingénierie |

> Sur un projet individuel, les rôles de Scrum Master et d'équipe de développement sont tenus par la même personne. Le Product Owner reste une personne distincte, ce qui garantit une validation externe de chaque incrément.

## 2. Artefacts

- **Product Backlog** : l'ensemble des user stories du projet. Chaque story suit le format « En tant que… je veux… afin de… », avec des critères d'acceptation, une priorité MoSCoW (`must` / `should` / `could`) et une estimation en story points (suite de Fibonacci : 1, 2, 3, 5, 8).
- **Sprint Backlog** : les stories rattachées au milestone du sprint en cours.
- **Incrément** : la version de la plateforme livrée en fin de sprint (image Docker publiée, manifestes appliqués, tableaux de bord).

## 3. Cérémonies

| Cérémonie | Fréquence | Durée | Contenu |
|---|---|---|---|
| Sprint Planning | Début de chaque sprint | 1 h | Choix des stories, définition de l'objectif du sprint |
| Daily Scrum | Chaque jour de travail | 10 min | Fait hier / prévu aujourd'hui / obstacles (noté dans le journal) |
| Sprint Review | Fin de chaque sprint | 30 min | Démonstration de l'incrément au Product Owner |
| Sprint Retrospective | Fin de chaque sprint | 20 min | Ce qui a fonctionné / à améliorer / actions |

Durée d'un sprint : **2 semaines**.

## 4. Definition of Ready (DoR)

Une story peut entrer dans un sprint si :
- elle est rédigée au format user story et possède des critères d'acceptation ;
- elle est estimée en story points ;
- ses dépendances sont identifiées.

## 5. Definition of Done (DoD)

Une story est terminée quand :
- le code ou la configuration est commité sur `main` ;
- le pipeline CI/CD est vert (build, scan Trivy, publication) ;
- aucune vulnérabilité CRITICAL n'est introduite ;
- l'incrément est déployé et vérifié sur Minikube (pods `Running`, pages HTTP 200) ;
- les critères d'acceptation sont validés et la documentation est à jour.

## 6. Planification des sprints

| Sprint | Période | Objectif | Points |
|---|---|---|---|
| Sprint 1 | 14/09 → 27/09/2026 | Application conteneurisée, connectée à PostgreSQL, lançable en une commande | 15 |
| Sprint 2 | 28/09 → 11/10/2026 | Chaque push construit et publie automatiquement l'image | 10 |
| Sprint 3 | 12/10 → 25/10/2026 | Infrastructure décrite en manifestes Kubernetes | 19 |
| Sprint 4 | 26/10 → 08/11/2026 | Déploiement Minikube, supervision, image sans vulnérabilité connue | 29 |
| Sprint 5 | 09/11 → 22/11/2026 | Anomalies corrigées, déploiement proche de la production | 21 |
| Sprint 6 | 23/11 → 06/12/2026 | Rapport final et soutenance | 13 |

**Total : 25 user stories, 107 story points.** Le détail se trouve dans [backlog.json](backlog.json) et sur le tableau GitHub Projects.

## 7. Épopées (epics)

| Epic | Contenu |
|---|---|
| `epic:docker` | Conteneurisation, PostgreSQL, Docker Compose |
| `epic:ci-cd` | GitHub Actions, Docker Hub, tests, déploiement continu |
| `epic:kubernetes` | Minikube, manifestes, déploiement, données |
| `epic:monitoring` | Prometheus, Grafana, stabilité |
| `epic:securite` | Secrets, Trivy, correctifs, durcissement |
| `epic:application` | Évolutions et anomalies fonctionnelles |
| `epic:documentation` | Rapport et soutenance |
