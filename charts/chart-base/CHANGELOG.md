# Changelog — chart-base

## 0.2.0

Primeira release pública (vinda do `chart-base 0.1.4` interno do GitLab Sanasa). Inclui mudanças **breaking** no selector — instalações vindas de 0.1.x exigem `helm uninstall` + `helm install` (selectors são imutáveis).

> **Distribuição**: a partir desta versão, o chart é publicado como package OCI privado em `oci://ghcr.io/rst-services/charts/chart-base`. Veja [`docs/onboarding-cliente.md`](../../docs/onboarding-cliente.md) para autenticação.

### Adicionado

- **`kind: Deployment | StatefulSet`** — toggle de tipo de workload. Quando StatefulSet, suporta `serviceName`, `podManagementPolicy`, `updateStrategy` e `volumeClaimTemplates` (PVC por pod via ordinal).
- **`service.headless`** — quando `true`, Service vira `clusterIP: None` (necessário para identidade DNS estável em StatefulSet).
- **`env: []`** — lista nativa do k8s, suporta `valueFrom` (fieldRef, configMapKeyRef, secretKeyRef).
- **`envFrom: []`** — referências adicionais além do configmap/secret deste chart.
- **`extraVolumes` / `extraVolumeMounts`** — escape hatch para volumes (configmap, secret, emptyDir, etc.) sem precisar forkar o chart.
- **`initContainers: []`** — lista de init containers customizados.
- **`podSecurityContext` / `securityContext`** — PSA-friendly defaults (`runAsNonRoot`, `readOnlyRootFilesystem`, drop capabilities).
- **`tolerations`, `affinity`, `topologySpreadConstraints`, `priorityClassName`** — agendamento completo.
- **`podAnnotations` / `podLabels`** — para Prometheus scrape, Vault inject, NetworkPolicy selectors etc.
- **`serviceAccount.create / name / annotations`** — IRSA (EKS) e Workload Identity (GKE) suportados.
- **`image.digest`** — pinning por digest sobrescreve `image.tag`.
- **`secret`** agora usa `stringData` (sem necessidade de base64 manual).

### Modificado (breaking)

- **`selectorLabels`** removeu `app.kubernetes.io/component`. Selector agora é apenas `name` + `instance`. Como selectors são imutáveis, upgrade exige delete+install.
- **`deployment.yaml` → `workload.yaml`** — template unificado. Sem impacto em values, só renomeação.
- `metadata.name` em todos os recursos agora usa `chart-base.fullname`. Antes era `Release.Name` puro — pode mudar nomes de objetos em alguns casos. Use `fullnameOverride: <release-name>` para preservar.

### Corrigido

- `indent` → `nindent` no Deployment/Service onde apropriado (eliminou bug latente de YAML quebrado em values incomuns).
- `with .Values.nodeSelector` agora usa `.` interno em vez de `.Values.nodeSelector` redundante.
- `gateway.uniqueHosts` não emite mais linha em branco no início da lista.

### Removido

- `envVariables: {}` (dead code, não era referenciado em nenhum template). Use `env`/`envFrom`/`configmap.variables` no lugar.
