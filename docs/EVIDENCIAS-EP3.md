# Evidencias EP3 — Istio, Kiali y CloudWatch

Repositorio: `DOYO101-005V-EP3`  
App: Tienda de Alimentos para Perritos (cuatro microservicios).

Marca cada ítem cuando tengas la captura o el log. No inventar resultados.

## IE1 — Clúster EKS con eksctl (20 %)

- [ ] Archivo usado: `infra/eks/cluster.yaml` → `cluster.generated.yaml` con `LabRole`
- [ ] Comando: `./scripts/ep3-01-create-cluster.sh`
- [ ] **Captura:** `kubectl get nodes` con nodos Ready
- [ ] **Captura:** salida de `eksctl` / CloudFormation stacks en éxito
- [ ] Confirmación: no se crearon roles IAM nuevos (solo LabRole)

## IE2 — Istio + sidecars (20 %)

- [ ] Namespace `tienda` con `istio-injection=enabled`
- [ ] **Captura:** `kubectl -n tienda get pods` mostrando **2/2 Running** en frontend, backend, reporting-service y db
- [ ] Workloads: `k8s/02-mysql.yaml` … `05-frontend.yaml`

## IE3 — Kiali + Prometheus + tráfico (20 %)

- [ ] Addons aplicados; Service `kiali` tipo LoadBalancer
- [ ] **Captura:** URL/hostname del LB de Kiali
- [ ] **Captura:** grafo del namespace `tienda` con flechas frontend↔backend↔reporting↔db (según rutas observadas)
- [ ] Tráfico generado con `./scripts/ep3-07-traffic.sh`
- [ ] Nota breve: rutas vistas, latencias o errores (si hubo)

## IE4 — CloudWatch Container Insights (15 %)

- [ ] Intento/addon: `./scripts/ep3-06-cloudwatch.sh`
- [ ] **Captura:** métricas CPU/memoria del clúster o workloads en CloudWatch
- [ ] **Captura o nota:** logs de contenedores visibles
- [ ] Párrafo propio: diferencia Kiali/Prometheus (malla) vs CloudWatch (infra)

## IE5 — Documentación (15 %)

- [ ] README con arquitectura malla vs infraestructura
- [ ] Diagrama o esquema de flujo (README)
- [ ] Explicación de cómo apoya decisiones técnicas (ej. error 5xx en Kiali vs nodo saturado en CloudWatch)

## IE6 — Limpieza (10 %)

- [ ] `./scripts/ep3-99-cleanup.sh` ejecutado
- [ ] **Captura:** clúster eliminado / `describe-cluster` fallando
- [ ] **Captura:** sin LB huérfanos relevantes en EC2 → Load Balancers

## Reflexión personal (obligatoria, sin IA)

> Escribe aquí tu aprendizaje y contribución (tú solo). No uses IA para este párrafo.

___________________________________________________________________________
___________________________________________________________________________
___________________________________________________________________________
