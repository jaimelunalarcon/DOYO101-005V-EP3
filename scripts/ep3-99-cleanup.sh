#!/usr/bin/env bash
# IE6: limpieza completa del Lab (clúster, nodos, LB) + ECR opcional.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"
CLUSTER="${CLUSTER_NAME:-doy0101-tienda}"
OUT="$ROOT/infra/eks/cluster.generated.yaml"

echo "==> Borrando clúster EKS (elimina nodos y balanceadores asociados)"
if [[ -f "$OUT" ]]; then
  eksctl delete cluster -f "$OUT" --wait
else
  eksctl delete cluster --name "$CLUSTER" --region "$REGION" --wait
fi

echo "==> (Opcional) Destruir ECR con Terraform"
read -r -p "¿terraform destroy ECR? [y/N] " ans
if [[ "${ans:-N}" =~ ^[Yy]$ ]]; then
  (cd "$ROOT/infra/terraform" && terraform destroy -auto-approve)
fi

echo "==> Verificación rápida (no deben quedar LB/nodos del clúster)"
aws eks describe-cluster --name "$CLUSTER" --region "$REGION" 2>&1 | head -5 || echo "Clúster eliminado OK"
aws elbv2 describe-load-balancers --region "$REGION" --query 'LoadBalancers[].LoadBalancerName' --output text || true
echo "Limpieza finalizada. Revisa también la consola EC2/VPC del Lab."
