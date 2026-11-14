#!/usr/bin/env bash
# Restauration d'une sauvegarde PostgreSQL produite par le CronJob postgres-backup.
#
#   ./scripts/restore-postgres.sh --liste             liste les sauvegardes
#   ./scripts/restore-postgres.sh --test  [fichier]   restaure dans une base de TEST (sans risque)
#   ./scripts/restore-postgres.sh --prod  [fichier]   restaure dans la base de PRODUCTION
#
# Sans fichier, la sauvegarde la plus récente est utilisée.
set -euo pipefail
NS=formation; POD=postgres-restore
MODE=${1:---liste}; FILE=${2:-}
case "$MODE" in --liste|--test|--prod) ;; *) sed -n '2,8p' "$0"; exit 1 ;; esac

# Pod temporaire monté sur le volume des sauvegardes
kubectl -n $NS delete pod $POD --ignore-not-found --wait=true >/dev/null
kubectl -n $NS apply -f - >/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata: { name: $POD, namespace: $NS }
spec:
  restartPolicy: Never
  containers:
    - name: restore
      image: postgres:15
      imagePullPolicy: IfNotPresent
      command: ["sleep", "3600"]
      env:
        - { name: PGHOST, value: postgres }
        - name: PGUSER
          valueFrom: { secretKeyRef: { name: formation-secret, key: POSTGRES_USER } }
        - name: PGPASSWORD
          valueFrom: { secretKeyRef: { name: formation-secret, key: POSTGRES_PASSWORD } }
        - name: PGDATABASE
          valueFrom: { configMapKeyRef: { name: formation-config, key: POSTGRES_DB } }
      volumeMounts: [{ name: backup, mountPath: /backup }]
  volumes:
    - name: backup
      persistentVolumeClaim: { claimName: postgres-backup }
EOF
trap 'kubectl -n $NS delete pod $POD --ignore-not-found --wait=false >/dev/null' EXIT
kubectl -n $NS wait --for=condition=Ready pod/$POD --timeout=120s >/dev/null
ex() { kubectl -n $NS exec $POD -- sh -c "$1"; }

[ -n "$FILE" ] || FILE=$(ex 'ls -1t /backup/*.dump | head -1')

case "$MODE" in
  --liste) ex 'ls -lh /backup/' ;;
  --test)
    echo "Sauvegarde : $FILE"
    ex 'psql -qc "DROP DATABASE IF EXISTS restore_test" && psql -qc "CREATE DATABASE restore_test"'
    ex "pg_restore --no-owner -d restore_test '$FILE'"
    echo "Contrôle de la base restaurée (restore_test) :"
    ex "psql -d restore_test -tAc \"select 'tables', count(*) from information_schema.tables where table_schema='public' union all select 'formations', count(*) from base_formation union all select 'utilisateurs', count(*) from auth_user\""
    echo "Base de production, pour comparaison :"
    ex "psql -tAc \"select 'tables', count(*) from information_schema.tables where table_schema='public' union all select 'formations', count(*) from base_formation union all select 'utilisateurs', count(*) from auth_user\""
    ex 'psql -qc "DROP DATABASE restore_test"' && echo "Base de test supprimée."
    ;;
  --prod)
    read -r -p "Restaurer $FILE en PRODUCTION (les données actuelles seront remplacées) ? [oui/non] " R
    [ "$R" = "oui" ] || { echo "Annulé."; exit 1; }
    ex "pg_restore --clean --if-exists --no-owner -d \$PGDATABASE '$FILE'" && echo "Restauration terminée."
    ;;
esac
