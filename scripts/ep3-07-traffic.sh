#!/usr/bin/env bash
# Genera tráfico real para el grafo de Kiali (rutas, latencias).
set -euo pipefail

INGRESS_HOST="$(kubectl -n istio-system get svc istio-ingressgateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"

if [[ -z "$INGRESS_HOST" ]]; then
  echo "Ingress sin hostname aún. Port-forward temporal:"
  echo "  kubectl -n istio-system port-forward svc/istio-ingressgateway 8080:80"
  BASE="http://127.0.0.1:8080"
else
  BASE="http://${INGRESS_HOST}"
fi

echo "Base: $BASE"
for i in $(seq 1 40); do
  curl -fsS -o /dev/null "$BASE/productos" || true
  curl -fsS -o /dev/null "$BASE/api/productos" || true
  curl -fsS -o /dev/null "$BASE/api/health" || true
  curl -fsS -o /dev/null "$BASE/reports/summary" || true
  curl -fsS -o /dev/null "$BASE/reports/low-stock?threshold=5" || true
  curl -fsS -o /dev/null "$BASE/reports/top-value?limit=5" || true
  sleep 1
done
echo "Tráfico enviado. Abre Kiali → Graph → namespace tienda (últimos minutos)."
kubectl -n istio-system get svc kiali
