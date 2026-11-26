# DOYO101 — EP3: Observabilidad de microservicios con Istio, Kiali y CloudWatch

**Asignatura:** DOY0101 Ingeniería DevOps · **Evaluación Parcial N°3** 

Despliegue de la **Tienda de Alimentos para Perritos** (cuatro microservicios) en un clúster **Amazon EKS**, con malla de servicios **Istio**, visualización de tráfico en **Kiali + Prometheus** y observabilidad de infraestructura con **AWS CloudWatch** (Container Insights y logs).



## Arquitectura de observabilidad (IE5)

```text
                         Internet
                            │
              ┌─────────────▼──────────────┐
              │  Istio IngressGateway (LB) │
              └─────────────┬──────────────┘
                            │
         VirtualService / Gateway (k8s/06-gateway.yaml)
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   /api/*              /reports/*              /* 
        │                   │                   │
   backend              reporting            frontend
   (Express)            (FastAPI)            (Nginx)
        │                   │
        └────────► db (MySQL) ◄──────────────┘
                   (vía backend)

  Namespace tienda → label istio-injection=enabled
  Cada pod de app: contenedor de negocio + sidecar Envoy → 2/2 Running

  ┌─────────────────────────────┐   ┌────────────────────────────────┐
  │ Kiali + Prometheus (malla)  │   │ CloudWatch (infraestructura)   │
  │ Rutas, RPS, latencias,      │   │ CPU, memoria, logs de pods/    │
  │ errores HTTP entre servicios│   │ nodos (Container Insights)     │
  └─────────────────────────────┘   └────────────────────────────────┘
```

### Qué muestra cada herramienta (malla vs infraestructura)

| Capa | Herramienta | Pregunta que responde | Qué no responde |
| --- | --- | --- | --- |
| **Malla de servicios** | **Kiali + Prometheus** | ¿Quién llama a quién? ¿Hay errores 4xx/5xx, latencias altas o caída de RPS entre frontend, backend, reporting y db? | Uso de CPU/RAM del nodo, disco EBS o salud del control plane de EKS |
| **Infraestructura** | **CloudWatch Container Insights + logs** | ¿El nodo o el contenedor está saturado de CPU/memoria? ¿Qué dice el log del pod? | El grafo de llamadas servicio a servicio ni las métricas de tráfico HTTP de la malla |

Ambas capas son complementarias: Kiali explica el **comportamiento del tráfico**; CloudWatch explica el **estado de los recursos** que sostienen ese tráfico.

### Cómo apoyan la toma de decisiones técnicas

| Síntoma | Señal en Kiali / Prometheus | Señal en CloudWatch | Decisión típica |
| --- | --- | --- | --- |
| API lenta o timeouts | Latencia alta en arista frontend→backend o backend→db | CPU/memoria del pod o del nodo elevados | Escalar réplicas / tipo de instancia vs. optimizar consulta o timeout |
| Errores 5xx en `/api` | Arista roja o tasa de error en el grafo | Logs del contenedor `backend` con stacktrace | Corregir bug o dependencia; no “agrandar” el clúster a ciegas |
| App “caída” pero grafo sin tráfico | Poco o nulo tráfico hacia un servicio | Pods `Pending`/`OOMKilled` o nodo sin capacidad | Revisar scheduling, límites de recursos o reinicios |
| Solo un servicio degradado | Una arista afectada; el resto sano | Solo ese workload con métricas anómalas | Aislar el microservicio (rollout, config) sin tocar toda la malla |

---

## Requisitos del entorno

- AWS Academy **Learner Lab** abierto (credenciales vigentes; región típica `us-east-1`)
- Docker Desktop, AWS CLI v2, Terraform, `kubectl`
- `eksctl` e `istioctl` (pueden instalarse con `./scripts/ep3-00-prereqs.sh` vía Homebrew)

**Límite del Lab (IE1 / IE6):** usar el rol existente `LabRole`. **No crear roles IAM nuevos.** Terraform en este repo solo provisiona **ECR**; el clúster lo crea **eksctl** con el ARN de `LabRole`.

---

## Estructura del repositorio

```text
app/                  # frontend, backend, reporting-service, db
infra/eks/            # cluster.yaml (eksctl) — IE1
infra/terraform/      # ECR (imágenes de la tienda)
k8s/                  # Namespace, Secret, Deployments, Services, Gateway/VS
scripts/              # Runbook automatizado (IE1–IE6)
docs/EVIDENCIAS-EP3.md
```

Configuración del clúster: [`infra/eks/cluster.yaml`](infra/eks/cluster.yaml)  
- Nombre: `doy0101-tienda` · versión Kubernetes `1.31`  
- `serviceRoleARN` e `instanceRoleARN` → `LabRole`  
- Node group: 2 × `t3.medium` (Amazon Linux 2)

---

## Jornada de despliegue (orden exacto)

```bash
cd DOYO101-005V-EP3
export AWS_REGION=us-east-1

./scripts/ep3-00-prereqs.sh          # herramientas + verificación STS
./scripts/ep3-01-create-cluster.sh   # IE1 — eksctl + LabRole (~15–25 min)
./scripts/ep3-02-ecr-terraform.sh    # Terraform → repositorios ECR
./scripts/ep3-03-build-push.sh       # imágenes linux/amd64 → ECR
./scripts/ep3-04-deploy-app.sh       # namespace tienda + workloads
./scripts/ep3-05-install-istio.sh    # IE2/IE3 — Istio, sidecars, Kiali LB, Gateway
./scripts/ep3-07-traffic.sh          # tráfico real para el grafo de Kiali
./scripts/ep3-06-cloudwatch.sh       # IE4 — Container Insights (addon)
./scripts/ep3-99-cleanup.sh          # IE6 — borrar clúster, nodos y LB
```

### Verificaciones rápidas por indicador

```bash
# IE1 — nodos Ready
kubectl get nodes -o wide

# IE2 — sidecars (debe verse 2/2 Running en los pods de tienda)
kubectl -n tienda get pods
kubectl get ns tienda --show-labels   # istio-injection=enabled

# IE3 — Kiali expuesto y grafo con tráfico
kubectl -n istio-system get svc kiali
# Abrir EXTERNAL-IP de Kiali → Graph → namespace tienda (tras ep3-07-traffic.sh)

# IE4 — CloudWatch
# Consola: CloudWatch → Container Insights → EKS Clusters → doy0101-tienda
# (CPU, memoria y logs de contenedores)

# IE6 — tras cleanup: clúster y LB del Lab eliminados
aws eks describe-cluster --name doy0101-tienda --region us-east-1
aws elbv2 describe-load-balancers --region us-east-1 \
  --query 'LoadBalancers[].LoadBalancerName' --output text
```


## Operación responsable y limpieza (IE6)

Al cerrar la jornada de Lab:

```bash
./scripts/ep3-99-cleanup.sh
```

Ese script elimina el clúster EKS con `eksctl` (nodos y balanceadores asociados) y ofrece destruir ECR con Terraform. **Verificar en consola** que no queden el clúster, instancias EC2 del node group ni Load Balancers huérfanos; el Learner Lab tiene cupo de costo limitado.

---

## Uso de inteligencia artificial

- Se usó **Cursor** como apoyo para manifiestos, scripts de automatización y mejora de redacción/documentación.

**reflexión personal** 
- Lo importante de lo aprendido en esta unidad es acercarnos a nuevas herramientas de observabilidad, cuyo valor cuesta comprender en proyectos académicos, dado que el tráfico es prácticamente nulo en estos casos de ejemplo. Sin embargo, en entornos reales o de producción, estas herramientas constituyen una fuente muy importante de información para el mantenimiento y la mejora continua de los sistemas y, por sobre todo, permiten tener una mayor visibilidad y trazabilidad para detectar el origen de los problemas.

