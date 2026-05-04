# generic-workload-chart Specification

## Purpose
TBD - created by archiving change initial-charts-baseline. Update Purpose after archive.
## Requirements
### Requirement: Workload kind toggle

O chart `chart-base` SHALL gerar um único workload Kubernetes por release, com tipo (`Deployment` ou `StatefulSet`) determinado pelo valor `kind` no `values.yaml`. O default SHALL ser `Deployment`.

#### Scenario: Default produz Deployment

- **WHEN** o usuário instala o chart sem sobrescrever `kind`
- **THEN** o template renderiza um único recurso `apiVersion: apps/v1, kind: Deployment`

#### Scenario: kind StatefulSet produz StatefulSet com serviceName

- **WHEN** o usuário define `kind: StatefulSet` no values
- **THEN** o template renderiza `kind: StatefulSet` com `spec.serviceName` apontando para o Service do release (ou `statefulSet.serviceName` se sobrescrito)

#### Scenario: Valor inválido em kind

- **WHEN** o usuário define `kind: DaemonSet` (não suportado)
- **THEN** o template renderiza com `kind: DaemonSet` literal mas não popula campos específicos de StatefulSet (comportamento "passa adiante" — validação rígida fica para `values.schema.json` futuro)

### Requirement: Selector labels imutáveis e mínimos

O `spec.selector.matchLabels` do workload e o `selector` do Service SHALL conter apenas `app.kubernetes.io/name` e `app.kubernetes.io/instance`. Demais labels k8s recomendados (`version`, `component`, `part-of`, `managed-by`) SHALL aparecer em `metadata.labels` mas NÃO no selector.

#### Scenario: Selector contém apenas name e instance

- **WHEN** o template é renderizado com qualquer values
- **THEN** o `spec.selector.matchLabels` tem exatamente duas chaves: `app.kubernetes.io/name` e `app.kubernetes.io/instance`

#### Scenario: Labels informativos no metadata

- **WHEN** o template é renderizado
- **THEN** o `metadata.labels` do workload contém `helm.sh/chart`, `app.kubernetes.io/version`, `app.kubernetes.io/managed-by` além das duas do selector

### Requirement: Image digest sobrescreve tag

Quando `image.digest` é fornecido, o chart SHALL usar a referência por digest (`repo@sha256:...`) ignorando `image.tag`.

#### Scenario: Apenas tag fornecida

- **WHEN** o usuário define `image.repository=nginx, image.tag=1.27`
- **THEN** o container `image` é `nginx:1.27`

#### Scenario: Digest fornecido

- **WHEN** o usuário define `image.repository=nginx, image.digest=sha256:abc123`
- **THEN** o container `image` é `nginx@sha256:abc123`, independentemente do valor de `image.tag`

### Requirement: Secret gerado usa stringData

Quando `secret.enabled=true`, o Secret renderizado SHALL usar o campo `stringData` (não `data` base64-encoded).

#### Scenario: Variáveis em texto puro

- **WHEN** o usuário define `secret.enabled=true, secret.variables={API_KEY: "raw-value"}`
- **THEN** o Secret renderizado contém `stringData: { API_KEY: "raw-value" }` literalmente

### Requirement: StatefulSet com PVC por pod

Quando `kind: StatefulSet` e `statefulSet.volumeClaimTemplates` é não-vazio, o chart SHALL renderizar `spec.volumeClaimTemplates` no StatefulSet com PVCs por pod (ordinal). O container SHALL receber `volumeMounts` correspondentes derivados de `mountPath`.

#### Scenario: Volume claim template gera PVC por ordinal

- **WHEN** `statefulSet.volumeClaimTemplates` contém `[{name: data, size: 5Gi, mountPath: /var/lib/app}]`
- **THEN** o StatefulSet tem `volumeClaimTemplates[0]` com `metadata.name: data` e `resources.requests.storage: 5Gi`
- **AND** o container tem `volumeMounts` contendo `{name: data, mountPath: /var/lib/app}`

### Requirement: Service headless opcional

O chart SHALL renderizar Service como headless (`clusterIP: None`) quando `service.headless: true`, mantendo todas as portas declaradas.

#### Scenario: Headless habilitado

- **WHEN** o usuário define `service.headless: true`
- **THEN** o Service tem `spec.clusterIP: None`

#### Scenario: Headless desabilitado (default)

- **WHEN** o usuário não define `service.headless` ou define `false`
- **THEN** o Service NÃO tem `spec.clusterIP` (deixa o k8s atribuir)

### Requirement: Escape hatches genéricos

O chart SHALL aceitar `extraVolumes`, `extraVolumeMounts`, `initContainers`, `env` (formato nativo k8s com suporte a `valueFrom`), e `envFrom` (lista) sem precisar de fork.

#### Scenario: env com valueFrom

- **WHEN** o usuário define `env: [{name: POD_NAME, valueFrom: {fieldRef: {fieldPath: metadata.name}}}]`
- **THEN** o container `env` contém o item literal preservando `valueFrom`

#### Scenario: extraVolumes mesclam com volumes do chart

- **WHEN** o usuário define `extraVolumes: [{name: tmp, emptyDir: {}}]` em conjunto com PVCs do chart
- **THEN** o `spec.volumes` do pod contém tanto os PVCs do chart quanto os `extraVolumes`

### Requirement: Istio VirtualService + cert-manager opcionais

Quando `virtualService.enabled: true`, o chart SHALL gerar `VirtualService` (Istio). Quando adicionalmente `virtualService.letsEncrypt.enabled: true`, SHALL gerar também `Gateway` (Istio) e `Certificate` (cert-manager) no namespace `istio-system`.

#### Scenario: Recursos de Istio desabilitados por default

- **WHEN** o usuário não toca em `virtualService`
- **THEN** o template não emite recursos `VirtualService`, `Gateway` ou `Certificate`

#### Scenario: Hosts deduplicados em Gateway e Certificate

- **WHEN** múltiplas `virtualService.routes` listam o mesmo host
- **THEN** o `Gateway.spec.servers[].hosts` e `Certificate.spec.dnsNames` contêm cada FQDN exatamente uma vez

### Requirement: ServiceAccount opcional para IRSA/Workload Identity

O chart SHALL aceitar `serviceAccount.create: true` para criar um ServiceAccount com `serviceAccount.annotations` (suportando IRSA da AWS, Workload Identity do GCP, etc.). O workload SHALL referenciar o ServiceAccount via `spec.template.spec.serviceAccountName`.

#### Scenario: ServiceAccount criado e referenciado

- **WHEN** o usuário define `serviceAccount.create: true, serviceAccount.annotations: {eks.amazonaws.com/role-arn: arn:aws:iam::123:role/foo}`
- **THEN** um `ServiceAccount` é renderizado com a annotation
- **AND** o `serviceAccountName` do pod aponta para esse SA

#### Scenario: ServiceAccount default

- **WHEN** o usuário não muda `serviceAccount.create` (default `false`)
- **THEN** nenhum `ServiceAccount` é renderizado
- **AND** o `serviceAccountName` do pod é `default` (ou o valor de `serviceAccount.name` se definido)

