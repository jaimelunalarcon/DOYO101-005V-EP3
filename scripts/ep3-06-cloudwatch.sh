#!/usr/bin/env bash
# IE4: Container Insights / observabilidad EKS (addon Amazon CloudWatch Observability).
# En Learner Lab: si falla por IAM, documentar el intento y usar el panel CloudWatch disponible.
set -euo pipefail
REGION="${AWS_REGION:-us-east-1}"
CLUSTER="${CLUSTER_NAME:-doy0101-tienda}"

echo "==> Intentando addon amazon-cloudwatch-observability"
if aws eks create-addon \
  --cluster-name "$CLUSTER" \
  --addon-name amazon-cloudwatch-observability \
  --region "$REGION" 2>&1; then
  echo "Addon solicitado. Esperando ACTIVE..."
  aws eks wait addon-active --cluster-name "$CLUSTER" --addon-name amazon-cloudwatch-observability --region "$REGION" || true
else
  echo "WARN: create-addon falló (típico si el Lab no permite roles adicionales)."
  echo "Alternativa: habilitar Container Insights desde la consola EKS → Observability,"
  echo "o aplicar el manifiesto oficial de CloudWatch agent si el docente lo indica."
fi

aws eks describe-addon --cluster-name "$CLUSTER" --addon-name amazon-cloudwatch-observability --region "$REGION" 2>/dev/null \
  || echo "Addon no activo todavía."

echo "Consola: CloudWatch → Container Insights → EKS Clusters → $CLUSTER"
