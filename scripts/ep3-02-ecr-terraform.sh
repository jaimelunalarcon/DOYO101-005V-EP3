#!/usr/bin/env bash
# Terraform: crea repositorios ECR (acelerar push de imágenes).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/infra/terraform"
terraform init
terraform apply -auto-approve
terraform output
