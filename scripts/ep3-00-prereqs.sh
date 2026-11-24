#!/usr/bin/env bash
# Comprueba (e intenta instalar) herramientas de la jornada EP3.
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1; }

echo "==> Herramientas"
for c in aws kubectl terraform docker; do
  if need "$c"; then echo "OK  $c ($($c version 2>/dev/null | head -1 || true))"; else echo "FALTA $c"; fi
done

if ! need eksctl; then
  echo "Instalando eksctl..."
  brew install eksctl
fi
if ! need istioctl; then
  echo "Instalando istioctl..."
  brew install istioctl
fi

echo "==> Identidad AWS"
aws sts get-caller-identity
echo "==> Región: ${AWS_REGION:-us-east-1} (exporta AWS_REGION si aplica)"
echo "Prereqs listos."
