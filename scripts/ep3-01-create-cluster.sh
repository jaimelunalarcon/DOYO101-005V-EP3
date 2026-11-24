#!/usr/bin/env bash
# IE1: crea el clúster EKS con eksctl usando LabRole (sin roles IAM nuevos).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
SRC="$ROOT/infra/eks/cluster.yaml"
OUT="$ROOT/infra/eks/cluster.generated.yaml"

sed "s/ACCOUNT_ID/${ACCOUNT_ID}/g" "$SRC" > "$OUT"
echo "Cuenta: $ACCOUNT_ID"
echo "Config: $OUT"
echo "Creando clúster (15-25 min)..."
eksctl create cluster -f "$OUT"
aws eks update-kubeconfig --name doy0101-tienda --region "$REGION"
kubectl get nodes -o wide
echo "Clúster listo."
