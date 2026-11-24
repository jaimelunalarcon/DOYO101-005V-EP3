#!/usr/bin/env bash
# Build linux/amd64 y push a ECR (nodos EKS Academy son x86_64).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
PROJECT="${PROJECT:-doy0101-tienda}"
TAG="${IMAGE_TAG:-ep3}"

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

build_push() {
  local name="$1" context="$2"
  local image="${REGISTRY}/${PROJECT}/${name}:${TAG}"
  echo "==> $image"
  docker build --platform linux/amd64 -t "$image" "$context"
  docker push "$image"
}

build_push frontend "$ROOT/app/frontend"
build_push backend "$ROOT/app/backend"
build_push reporting-service "$ROOT/app/reporting-service"
build_push db "$ROOT/app/db"

echo "Imágenes en ECR con tag ${TAG}"
echo "REGISTRY=$REGISTRY"
echo "PROJECT=$PROJECT"
echo "TAG=$TAG"
