#!/usr/bin/env bash
# =====================================================================
#  Démonstration du PFE devant le jury
#  Plateforme de gestion des formations - architecture DevOps
#
#  ./scripts/demo.sh          toute la démo, étape par étape (Entrée pour continuer)
#  ./scripts/demo.sh 5        une seule étape (numéro)
#  ./scripts/demo.sh --liste  liste des étapes
#  DEMO_AUTO=1 ./scripts/demo.sh   sans pause (enregistrement vidéo)
# =====================================================================
set -uo pipefail
cd "$(dirname "$0")/.."
NS=formation
IP=$(minikube ip 2>/dev/null || echo 192.168.49.2)
HOST=formation.pfe.local
CA=~/pfe-tls/ca.crt

B=$'\e[1m'; C=$'\e[1;36m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; D=$'\e[2m'; R=$'\e[0m'

titre() { echo; echo "${C}══════════════════════════════════════════════════════════════════${R}";
          echo "${C}  $1${R}"; echo "${C}══════════════════════════════════════════════════════════════════${R}"; }
dire()  { echo "${Y}▶ $*${R}"; }
cmd()   { echo; echo "${G}\$ $*${R}"; eval "$@"; }
pause() { [ "${DEMO_AUTO:-0}" = 1 ] && { sleep "${1:-2}"; return; }
          echo; read -rp "${D}   [Entrée pour continuer]${R}" _; }

# ---------------------------------------------------------------------
etape1() { titre "1. L'infrastructure : un cloud privé local"
  dire "PC Windows → VirtualBox → VM Ubuntu → Docker → nœud Kubernetes (Minikube)"
  cmd "lsb_release -ds; nproc; free -h | sed -n 1,2p"
  cmd "minikube status | head -5"
  cmd "kubectl get nodes -o wide"
  pause; }

etape2() { titre "2. La plateforme déployée sur Kubernetes"
  dire "Namespace 'formation' : application (2 pods), PostgreSQL, Services, HPA, Ingress, CronJob"
  cmd "kubectl -n $NS get deploy,pods,svc -o wide"
  cmd "kubectl -n $NS get hpa,ingress,cronjob,pvc"
  pause; }

etape3() { titre "3. Configuration et secrets (jamais dans le code)"
  dire "ConfigMap = configuration non sensible ; Secret = mots de passe (valeurs masquées)"
  cmd "kubectl -n $NS get configmap formation-config -o jsonpath='{.data}' | jq ."
  cmd "kubectl -n $NS describe secret formation-secret | sed -n '/Data/,\$p'"
  pause; }

etape4() { titre "4. Accès sécurisé HTTPS (Ingress NGINX + TLS)"
  dire "HTTP est redirigé vers HTTPS (code 308)"
  cmd "curl -s -o /dev/null -w 'HTTP  → code %{http_code}, redirigé vers %{redirect_url}\n' --resolve $HOST:80:$IP http://$HOST/"
  dire "HTTPS : certificat vérifié avec l'autorité de certification du projet"
  cmd "curl -s -o /dev/null -w 'HTTPS → code %{http_code}, certificat vérifié = %{ssl_verify_result} (0 = OK)\n' --cacert $CA --resolve $HOST:443:$IP https://$HOST/"
  cmd "echo | openssl s_client -connect $IP:443 -servername $HOST 2>/dev/null | openssl x509 -noout -subject -issuer -enddate"
  pause; }

etape5() { titre "5. Haute disponibilité : auto-réparation"
  local P; P=$(kubectl -n $NS get pods -l app=web -o jsonpath='{.items[0].metadata.name}')
  dire "On supprime volontairement le pod $P (simulation d'une panne)"
  cmd "kubectl -n $NS delete pod $P --wait=false"
  dire "Kubernetes recrée immédiatement un nouveau pod ; l'autre pod continue de répondre"
  for i in 1 2 3 4 5 6; do
    code=$(curl -s -o /dev/null -w '%{http_code}' http://$IP:30080/)
    echo "${D}   t+$((i*5))s  application : HTTP $code${R}"; kubectl -n $NS get pods -l app=web --no-headers | sed 's/^/     /'
    sleep 5
  done
  cmd "kubectl -n $NS rollout status deploy/web --timeout=180s"
  pause; }

etape6() { titre "6. Mise à jour sans interruption (Rolling Update)"
  dire "Les pods sont remplacés un par un : un nouveau pod doit être prêt avant qu'un ancien soit supprimé"
  cmd "kubectl -n $NS rollout restart deploy/web"
  : > /tmp/demo-sonde.txt
  ( while :; do curl -s -o /dev/null -w '%{http_code}\n' --max-time 3 http://$IP:30080/ >> /tmp/demo-sonde.txt; sleep 1; done ) &
  local SONDE=$!
  cmd "kubectl -n $NS rollout status deploy/web --timeout=240s"
  kill $SONDE 2>/dev/null; wait $SONDE 2>/dev/null
  dire "Requêtes envoyées à l'application pendant la mise à jour (une par seconde) :"
  sort /tmp/demo-sonde.txt | uniq -c | awk '{print "     " $1 " réponses avec le code HTTP " $2}'
  dire "Uniquement des codes 200 = aucune coupure de service"
  cmd "kubectl -n $NS rollout history deploy/web | tail -4"
  pause; }

etape7() { titre "7. Élasticité : auto-scaling (HPA) sous charge"
  dire "Règle : de 2 à 5 pods, cible 70 % de CPU. On simule 40 utilisateurs simultanés avec k6"
  cmd "kubectl -n $NS get hpa web"
  docker run --rm -i --network host -e BASE_URL=http://$IP:30080 grafana/k6:1.8.2 run --quiet \
    --stage 20s:10 --stage 160s:40 --stage 10s:0 - < loadtest/charge.js > /tmp/k6-demo.txt 2>&1 &
  local K6=$!
  dire "Pendant le test (environ 3 min) : ouvrir Grafana pour voir le CPU monter"
  for i in $(seq 1 19); do
    sleep 10
    read -r cpu cur des < <(kubectl -n $NS get hpa web -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization} {.status.currentReplicas} {.status.desiredReplicas}')
    printf '   t+%3ss   CPU moyen : %4s %% (cible 70 %%)   pods : %s → %s\n' $((i*10)) "${cpu:-?}" "${cur:-?}" "${des:-$cur}"
  done
  wait $K6
  dire "Résultat du test de charge"
  grep -E '(http_req_failed|http_req_duration|http_reqs|checks_succeeded)\.\.\.' /tmp/k6-demo.txt | sed 's/^ */     /'
  cmd "kubectl -n $NS get pods -l app=web"
  dire "Après 2 minutes de calme, l'HPA redescend progressivement à 2 pods"
  pause; }

etape8() { titre "8. Sauvegarde et restauration de PostgreSQL"
  dire "Le CronJob sauvegarde la base chaque nuit à 2 h. On déclenche une sauvegarde maintenant"
  local J=demo-sauvegarde-$(date +%H%M%S)
  cmd "kubectl -n $NS create job $J --from=cronjob/postgres-backup"
  cmd "kubectl -n $NS wait --for=condition=complete job/$J --timeout=120s"
  cmd "kubectl -n $NS logs job/$J"
  dire "Restauration dans une base de TEST, puis comparaison avec la production"
  cmd "./scripts/restore-postgres.sh --test 2>&1 | tail -12"
  kubectl -n $NS delete job $J --wait=false >/dev/null 2>&1
  pause; }

etape9() { titre "9. Infrastructure as Code (Terraform)"
  dire "Trois couches : infra (cluster 2 nœuds), app (déploiement), azure (AKS, prêt)"
  cmd "ls terraform/infra terraform/app terraform/azure"
  cmd "sed -n '/resource \"minikube_cluster\"/,/^}/p' terraform/infra/main.tf"
  dire "Ressources gérées par Terraform (état enregistré)"
  cmd "terraform -chdir=terraform/infra state list; terraform -chdir=terraform/app state list"
  dire "Commande unique : ./scripts/tf-apply.sh (création complète en ≈ 11 min) / tf-destroy.sh"
  pause; }

etape10() { titre "10. CI/CD et DevSecOps (GitHub Actions + Trivy)"
  dire "Chaque push déclenche : tests (19) → build → scan Trivy → publication Docker Hub"
  cmd "git log --oneline -6"
  cmd "sed -n '/Vérification et tests/,/test base/p' .github/workflows/ci-cd.yml"
  cmd "grep -n 'trivy-action' .github/workflows/ci-cd.yml"
  dire "À montrer dans le navigateur : GitHub → Actions (pipeline vert) et Security (0 alerte)"
  pause; }

ETAPES=(etape1 etape2 etape3 etape4 etape5 etape6 etape7 etape8 etape9 etape10)
case "${1:-}" in
  --liste) grep -E '^etape[0-9]+\(\) \{ titre' "$0" | sed -E 's/^etape([0-9]+).*titre "(.*)"/\2/' ;;
  "")      clear; echo "${B}Démonstration - Plateforme de gestion des formations (DevOps)${R}"; pause
           for e in "${ETAPES[@]}"; do $e; done; titre "Fin de la démonstration - merci !" ;;
  *)       "etape$1" ;;
esac
