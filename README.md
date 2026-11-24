# DOYO101-005V-EP3 — Observabilidad con Istio, Kiali y CloudWatch

Evaluación Parcial 3 (Ingeniería DevOps). Despliega la **Tienda de Alimentos para Perritos** en EKS, con malla Istio, Kiali/Prometheus y CloudWatch Container Insights.

Este repositorio es **independiente** de la entrega EP2 (`DOYO101-005V`). Solo reutiliza el código de los cuatro microservicios.

## Arquitectura

```text
Internet → Istio IngressGateway (LB)
              ├─ /api/*      → backend (Express) → db (MySQL)
              ├─ /reports/*  → reporting-service (FastAPI) → backend
              └─ /*          → frontend (Nginx)

Sidecars Envoy en cada pod del namespace tienda (2/2 Running).
Kiali + Prometheus observan el tráfico de la malla.
CloudWatch observa CPU/memoria/logs de infraestructura.
```

| Herramienta | Qué responde | Qué no responde |
| --- | --- | --- |
| **Kiali + Prometheus** | Rutas entre servicios, RPS, latencias, errores HTTP de la malla | Uso de CPU del nodo o disco EBS |
| **CloudWatch Container Insights** | CPU, memoria, logs de contenedores/nodos | Grafo de llamadas servicio a servicio |

## Requisitos

- AWS Academy **Learner Lab** abierto (credenciales vigentes)
- Docker Desktop, AWS CLI, Terraform, kubectl
- `eksctl` e `istioctl` (el script `ep3-00-prereqs.sh` puede instalarlos con Homebrew)

## Jornada (orden exacto)

```bash
cd DOYO101-005V-EP3
export AWS_REGION=us-east-1

./scripts/ep3-00-prereqs.sh          # herramientas + sts
./scripts/ep3-01-create-cluster.sh   # IE1 — eksctl + LabRole (~15-25 min)
./scripts/ep3-02-ecr-terraform.sh    # Terraform ECR
./scripts/ep3-03-build-push.sh       # imágenes linux/amd64 → ECR
./scripts/ep3-04-deploy-app.sh       # namespace tienda + workloads
./scripts/ep3-05-install-istio.sh    # IE2/IE3 — Istio, sidecars, Kiali LB, Gateway
./scripts/ep3-07-traffic.sh          # tráfico para el grafo
./scripts/ep3-06-cloudwatch.sh       # IE4 — Container Insights (addon)
# capturas → docs/EVIDENCIAS-EP3.md
./scripts/ep3-99-cleanup.sh          # IE6 — borrar clúster y LB
```

**Importante (IE1):** el clúster se crea con **eksctl** y el rol `LabRole` del Lab. Terraform solo acelera **ECR**; no crea roles IAM.

## Estructura

```text
app/                 # frontend, backend, reporting-service, db
infra/eks/           # cluster.yaml (eksctl)
infra/terraform/     # ECR
k8s/                 # Namespace, Secret, Deployments, Services, Gateway
scripts/             # Runbook automatizado
docs/EVIDENCIAS-EP3.md
```

## Evidencias

Checklist y marcadores de capturas: [docs/EVIDENCIAS-EP3.md](docs/EVIDENCIAS-EP3.md).

## Uso de IA

Durante la preparación del repositorio se usó Cursor como apoyo para manifiestos, scripts y documentación. La ejecución en el Learner Lab, las capturas, el análisis del grafo y la **reflexión personal** son del estudiante (sin IA en la reflexión, según pauta).

## Limpieza

Al terminar la jornada: `./scripts/ep3-99-cleanup.sh`. Verifica en la consola que no queden el clúster, nodos ni Load Balancers del Lab.
