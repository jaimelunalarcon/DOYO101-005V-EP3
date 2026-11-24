#!/usr/bin/env bash
# Sustituye placeholders IMAGE_* y aplica manifiestos k8s (namespace con istio-injection).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
PROJECT="${PROJECT:-doy0101-tienda}"
TAG="${IMAGE_TAG:-ep3}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for f in "$ROOT"/k8s/*.yaml; do
  sed \
    -e "s|IMAGE_FRONTEND|${REGISTRY}/${PROJECT}/frontend:${TAG}|g" \
    -e "s|IMAGE_BACKEND|${REGISTRY}/${PROJECT}/backend:${TAG}|g" \
    -e "s|IMAGE_REPORTING|${REGISTRY}/${PROJECT}/reporting-service:${TAG}|g" \
    -e "s|IMAGE_DB|${REGISTRY}/${PROJECT}/db:${TAG}|g" \
    "$f" > "$TMP/$(basename "$f")"
done

# Namespace + secret + workloads primero; Gateway después de Istio (script 05).
kubectl apply -f "$TMP/00-namespace.yaml"
kubectl apply -f "$TMP/01-secrets.yaml"
kubectl apply -f "$TMP/02-mysql.yaml"
kubectl apply -f "$TMP/03-backend.yaml"
kubectl apply -f "$TMP/04-reporting.yaml"
kubectl apply -f "$TMP/05-frontend.yaml"

echo "Esperando pods (sidecars: 2/2 tras instalar Istio)..."
kubectl -n tienda get pods -o wide
echo "Si Istio ya está: kubectl -n tienda wait --for=condition=ready pod --all --timeout=300s"
