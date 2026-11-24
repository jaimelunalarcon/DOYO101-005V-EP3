#!/usr/bin/env bash
# IE2 + IE3: Istio demo profile, reinicia pods para sidecars, addons Kiali+Prometheus, LB.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
PROJECT="${PROJECT:-doy0101-tienda}"
TAG="${IMAGE_TAG:-ep3}"

echo "==> Instalando Istio (profile demo)"
istioctl install --set profile=demo -y

kubectl label namespace tienda istio-injection=enabled --overwrite
kubectl -n tienda rollout restart deploy
kubectl -n tienda rollout status deploy --timeout=300s || true

echo "==> Addons Kiali + Prometheus (+ grafana/jaeger del sample)"
ISTIO_VER="$(istioctl version --remote=false 2>/dev/null | head -1 | awk '{print $NF}' || true)"
# samples viven en el release de Istio; usar URL oficial del tag instalado si hace falta
ADDONS_DIR="$(dirname "$(dirname "$(command -v istioctl)")")/share/istio/samples/addons"
if [[ ! -d "$ADDONS_DIR" ]]; then
  # Homebrew / curl fallback
  TMP="$(mktemp -d)"
  VER="$(istioctl version --remote=false -s 2>/dev/null || istioctl version --remote=false | awk '/client/{print $3; exit}')"
  VER="${VER:-1.22.0}"
  curl -fsSL "https://github.com/istio/istio/releases/download/${VER}/istio-${VER}-osx.tar.gz" \
    -o "$TMP/istio.tgz" 2>/dev/null \
  || curl -fsSL "https://github.com/istio/istio/releases/download/${VER}/istio-${VER}-osx-arm64.tar.gz" -o "$TMP/istio.tgz"
  tar -xzf "$TMP/istio.tgz" -C "$TMP"
  ADDONS_DIR="$(find "$TMP" -type d -path '*/samples/addons' | head -1)"
fi

kubectl apply -f "$ADDONS_DIR"
kubectl -n istio-system rollout status deployment/kiali --timeout=300s || true
kubectl -n istio-system patch svc kiali -p '{"spec":{"type":"LoadBalancer"}}'

# Gateway de la tienda
sed \
  -e "s|IMAGE_FRONTEND|${REGISTRY}/${PROJECT}/frontend:${TAG}|g" \
  "$ROOT/k8s/06-gateway.yaml" | kubectl apply -f -

echo "==> Pods tienda (esperado 2/2)"
kubectl -n tienda get pods
echo "==> Kiali LB"
kubectl -n istio-system get svc kiali
echo "==> Ingress Gateway"
kubectl -n istio-system get svc istio-ingressgateway
