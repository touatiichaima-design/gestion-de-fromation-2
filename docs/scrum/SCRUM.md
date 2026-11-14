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

## 6. Planification des sprints (ordre logique des dépendances)

Le Product Backlog est ordonné selon les **dépendances techniques** : chaque story ne commence que lorsque celles dont elle dépend sont terminées.

| Sprint | Période | Objectif | Points |
|---|---|---|---|
| Sprint 1 - Fondations : application conteneurisée | 14/09 → 27/09/2026 | Disposer d'une application Django configurée par variables d'environnement, connectée à PostgreSQL et lançable en une commande avec Docker Compose. | 15 |
| Sprint 2 - Qualité et intégration continue | 28/09 → 11/10/2026 | Un dépôt propre et sans secret, un code corrigé et testé, et un pipeline qui teste, construit et publie l'image à chaque push. | 18 |
| Sprint 3 - Sécurité DevSecOps et image de production | 12/10 → 25/10/2026 | Une image de production analysée par Trivy, sans vulnérabilité connue, durcie, et servie par Gunicorn avec DEBUG=False. | 21 |
| Sprint 4 - Orchestration Kubernetes et Infrastructure as Code | 26/10 → 08/11/2026 | Déployer la plateforme sur Kubernetes, puis décrire tout le cluster et le déploiement en code avec Terraform. | 29 |
| Sprint 5 - Exploitation : HTTPS, supervision, élasticité, sauvegardes | 09/11 → 22/11/2026 | Exposer la plateforme en HTTPS, la superviser, l'adapter automatiquement à la charge et sécuriser ses données par des sauvegardes. | 24 |
| Sprint 6 - Rapport et soutenance | 23/11 → 06/12/2026 | Livrer le rapport final et réussir la démonstration de soutenance. | 13 |

### Ordre des stories dans chaque sprint

**Sprint 1 - Fondations : application conteneurisée**
1. #4 Externaliser la configuration dans des variables d'environnement
2. #2 Migrer la base de données de SQLite vers PostgreSQL
3. #1 Conteneuriser l'application Django
4. #3 Orchestrer l'environnement local avec Docker Compose

**Sprint 2 - Qualité et intégration continue**
1. #6 Nettoyer le dépôt Git et purger les secrets de l'historique
2. #20 Retirer les données personnelles des médias de démonstration
3. #19 Bug : création d'une formation impossible si le nom dépasse 17 caractères
4. #22 Ajouter des tests automatisés Django au pipeline
5. #5 Publier l'image sur Docker Hub
6. #7 Mettre en place le pipeline CI/CD GitHub Actions

**Sprint 3 - Sécurité DevSecOps et image de production**
1. #15 Scanner l'image Docker avec Trivy dans le pipeline
2. #16 Corriger les vulnérabilités détectées par Trivy
3. #17 Durcir l'image Docker
4. #21 Servir l'application avec Gunicorn et DEBUG=False

**Sprint 4 - Orchestration Kubernetes et Infrastructure as Code**
1. #8 Installer le cluster Kubernetes Minikube
2. #9 Écrire les manifestes de configuration (Namespace, ConfigMap, Secret, PVC)
3. #10 Déployer PostgreSQL sur Kubernetes
4. #11 Déployer l'application web avec 2 replicas
5. #12 Migrer les données de Docker Compose vers Kubernetes
6. #27 Infrastructure as Code avec Terraform (cluster multi-nœuds + application)

**Sprint 5 - Exploitation : HTTPS, supervision, élasticité, sauvegardes**
1. #28 Exposition HTTPS avec un Ingress NGINX
2. #13 Installer Prometheus et Grafana avec Helm
3. #14 Visualiser CPU et mémoire des pods dans Grafana
4. #18 Stabiliser la stack de monitoring
5. #26 Auto-scaling horizontal des pods (HPA) et test de charge
6. #29 Sauvegarde automatique de PostgreSQL et restauration

**Sprint 6 - Rapport et soutenance**
1. #24 Rédiger le rapport de PFE
2. #25 Préparer la soutenance et la démonstration

**Product Backlog (hors sprint)**
- #23 Déploiement continu (CD) vers le cluster : reportée, perspective (GitOps avec Argo CD)

**Total : 29 user stories, 128 story points** (107 livrés). Détail : [backlog.json](backlog.json) et tableau GitHub Projects.

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
