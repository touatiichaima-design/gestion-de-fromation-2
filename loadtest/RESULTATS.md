# Test de charge et auto-scaling (HPA) - 11/11/2026

## Protocole
- **Outil** : k6 1.8.2 ([charge.js](charge.js))
- **Scénario** : montée à 10 utilisateurs en 30 s, puis **40 utilisateurs simultanés pendant 3 min**, puis descente. Les pages consultées sont tirées au hasard (accueil, connexion, inscription, détail de formation, formateurs).
- **Objectifs** : moins de 1 % d'erreurs, 95 % des réponses en moins de 2 s.
- **Infrastructure** : Minikube à 1 nœud (2 vCPU, 3,5 Go), application Django + Gunicorn (2 workers par pod), PostgreSQL 15.
- **Auto-scaling** : HPA de 2 à 5 pods, cible 70 % de CPU ([05-hpa.yaml](../k8s/05-hpa.yaml)).

## Résultats

| Indicateur | Test 1 | Test 2 (sondes corrigées) |
|---|---|---|
| Requêtes traitées | 3 963 | **5 908** |
| Taux d'erreur | 4,23 % ❌ | **0,00 %** ✅ |
| Temps de réponse médian | 179 ms | 199 ms |
| p95 | 3,94 s ❌ | **1,37 s** ✅ |
| Débit | 16,5 req/s | **24,6 req/s** (+49 %) |
| Pods web (min → max) | 2 → 5 | 2 → 5 |

## Évolution de l'HPA (test 2)

| Heure | CPU moyen / cible | Pods |
|---|---|---|
| 22:11:07 | (démarrage) | 2 |
| 22:11:22 | 183 % / 70 % | 2 |
| 22:11:38 | 183 % / 70 % | **4** |
| 22:12:09 | 183 % / 70 % | **5** |
| 22:12:24 | 311 % / 70 % | 5 (maximum) |
| 22:15:28 | 20 % / 70 % | 5 (fin de la charge) |
| 22:17:30 | 2 % / 70 % | **4** (réduction progressive après 2 min de calme) |

## Analyse
1. **L'élasticité fonctionne.** L'HPA ajoute des pods en moins de 30 s quand le CPU dépasse la cible, puis les retire progressivement : `stabilizationWindowSeconds: 120` évite les oscillations.
2. **Test 1 : erreurs 500.** Le nœud unique saturait en CPU. La sonde de vie de PostgreSQL (délai par défaut : 1 s) a expiré et **Kubernetes a redémarré la base de données en pleine charge**. Correction : délais de sonde de 5 à 10 s, seuil d'échec à 6, requête CPU de PostgreSQL à 250m.
3. **Limite observée.** Même à 5 pods, le CPU reste au-dessus de la cible (311 %), car les pods se partagent les **2 mêmes vCPU**. L'auto-scaling horizontal des pods ne crée pas de capacité physique.
   **Conclusion :** en production, il faut un **cluster multi-nœuds avec auto-scaling des nœuds** (Cluster Autoscaler), ce qu'offrent les clouds publics (AKS, EKS, GKE).
