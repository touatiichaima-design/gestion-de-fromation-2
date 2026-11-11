// Test de charge k6 : simule des visiteurs qui consultent la plateforme
// Usage : docker run --rm -i --network host -e BASE_URL=http://$(minikube ip):30080 grafana/k6 run - < loadtest/charge.js
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = __ENV.BASE_URL || 'http://192.168.49.2:30080';

export const options = {
  stages: [
    { duration: '30s', target: 10 },   // montée progressive
    { duration: '3m',  target: 40 },   // pic : 40 utilisateurs simultanés
    { duration: '30s', target: 0 },    // fin
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],     // moins de 1 % d'erreurs
    http_req_duration: ['p(95)<2000'],  // 95 % des réponses en moins de 2 s
  },
};

const pages = ['/', '/accounts/login/', '/user/register/', '/docker-k8s/', '/formateurs/'];

export default function () {
  const res = http.get(BASE + pages[Math.floor(Math.random() * pages.length)]);
  check(res, { 'statut 200': (r) => r.status === 200 });
  sleep(0.5);
}
