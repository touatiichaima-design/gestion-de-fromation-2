#!/usr/bin/env bash
# Rend l'app, Grafana et Prometheus accessibles depuis Windows via l'IP de la VM.
# (Le NodePort Minikube 192.168.49.x n'est visible que depuis l'intérieur de la VM.)
# Usage : ./scripts/04-expose.sh        (à relancer après un redémarrage de la VM)
set -u
pkill -f "kubectl port-forward --address 0.0.0.0" 2>/dev/null
sleep 1
pf() { # namespace service port_local port_service
  nohup kubectl port-forward --address 0.0.0.0 -n "$1" "svc/$2" "$3:$4" >/tmp/pf-$2.log 2>&1 &
}
pf formation  web                              30080 8000
if kubectl get ns monitoring >/dev/null 2>&1; then
  pf monitoring monitoring-grafana                30300 80
  pf monitoring monitoring-kube-prometheus-prometheus 30090 9090
fi
sleep 3
IP=$(hostname -I | awk '{print $1}')
echo "Application : http://$IP:30080"
echo "Grafana     : http://$IP:30300"
echo "Prometheus  : http://$IP:30090"
