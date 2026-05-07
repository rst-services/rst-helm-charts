## ADDED Requirements

### Requirement: Configuração via extraEnv com naming nativo

O chart `zabbix-proxy` SHALL expor toda a configuração do Zabbix Proxy exclusivamente via `extraEnv` (lista no formato `env` nativo do Kubernetes), com chaves seguindo o naming do image `zabbix/zabbix-proxy-sqlite3` (`ZBX_HOSTNAME`, `ZBX_SERVER_HOST`, `ZBX_PROXYMODE`, `ZBX_PROXYBUFFERMODE`, `ZBX_TLSCONNECT`, etc). O chart SHALL NOT introduzir aliases, traduções ou campos first-class para envs `ZBX_*`.

#### Scenario: extraEnv repassa env nativo ao container

- **WHEN** o usuário define `extraEnv: [{name: ZBX_SERVER_HOST, value: "zbx.empresa.com"}, {name: ZBX_PROXYMODE, value: "0"}]`
- **THEN** o container `env` contém literalmente os dois itens com mesmos `name` e `value`

#### Scenario: extraEnv com valueFrom é preservado

- **WHEN** o usuário define `extraEnv: [{name: ZBX_HOSTNAME, valueFrom: {fieldRef: {fieldPath: metadata.name}}}]`
- **THEN** o container `env[0]` contém `name: ZBX_HOSTNAME` com `valueFrom.fieldRef.fieldPath: metadata.name` preservado

#### Scenario: extraEnv vazio não emite bloco env

- **WHEN** o usuário não define `extraEnv` (default `[]`)
- **THEN** o container renderizado não contém o bloco `env`
- **AND** o pod sobe usando os defaults do image (que pode falhar em runtime se `ZBX_SERVER_HOST` ausente — responsabilidade do cliente)

### Requirement: Workload é StatefulSet com identidade estável

O chart SHALL renderizar SEMPRE como `StatefulSet`. O nome do StatefulSet, do Service e dos pods SHALL ser o `Release.Name` diretamente (sem o sufixo `-<chart-name>` do padrão Bitnami), gerando pods com nomes curtos `<release>-0`, `<release>-1`. O chart SHALL usar `podManagementPolicy: Parallel` e `updateStrategy.type: RollingUpdate`.

#### Scenario: Nomes derivam de Release.Name diretamente

- **WHEN** o usuário executa `helm install zbx-cliente1 rst/zabbix-proxy`
- **THEN** existe um `StatefulSet` com `metadata.name: zbx-cliente1`
- **AND** existe um `Service` com `metadata.name: zbx-cliente1`
- **AND** os pods criados têm nome `zbx-cliente1-0`, `zbx-cliente1-1`, ...

### Requirement: Persistência opcional via volumeClaimTemplates

Quando `persistence.enabled: true` (default), o chart SHALL renderizar `spec.volumeClaimTemplates[0]` chamado `data`, com tamanho `persistence.size` (default `5Gi`), `persistence.accessMode` (default `ReadWriteOnce`), e opcionalmente `persistence.storageClass`. O container SHALL montar `data` em `/var/lib/zabbix`. Quando `persistence.enabled: false`, o chart SHALL montar `/var/lib/zabbix` como `emptyDir` (perda do buffer SQLite a cada restart — uso em dev/teste).

#### Scenario: Persistence default

- **WHEN** o usuário não toca em `persistence`
- **THEN** o StatefulSet tem `volumeClaimTemplates[0]` com `name: data, accessModes: [ReadWriteOnce], resources.requests.storage: 5Gi`
- **AND** o container monta `data` em `/var/lib/zabbix`

#### Scenario: Persistence desabilitada usa emptyDir

- **WHEN** `persistence.enabled: false`
- **THEN** o StatefulSet NÃO tem `volumeClaimTemplates`
- **AND** o pod tem um volume `data` do tipo `emptyDir: {}`
- **AND** o container monta `data` em `/var/lib/zabbix`

#### Scenario: StorageClass custom

- **WHEN** `persistence.enabled: true, persistence.storageClass: gp3`
- **THEN** o `volumeClaimTemplates[0].spec.storageClassName` é `"gp3"`

### Requirement: Service ClusterIP com porta 10051 nomeada

O chart SHALL renderizar um Service tipo `service.type` (default `ClusterIP`) expondo `service.port` (default `10051`) com `targetPort` apontando para a porta nomeada `zbx-proxy` do container. Quando `service.headless: true`, o Service SHALL ter `clusterIP: None`.

#### Scenario: Service default

- **WHEN** o usuário não toca em `service`
- **THEN** existe um `Service` com `type: ClusterIP, ports[0].port: 10051, targetPort: zbx-proxy`

#### Scenario: Headless habilitado

- **WHEN** `service.headless: true`
- **THEN** o Service tem `spec.clusterIP: None`

### Requirement: Security defaults non-root

O pod SHALL rodar com `runAsNonRoot: true, runAsUser: 1997, fsGroup: 1997` (alinhado ao usuário `zabbix` da imagem oficial). O container SHALL ter `allowPrivilegeEscalation: false` e `capabilities.drop: [ALL]`.

#### Scenario: Pod-level securityContext

- **WHEN** o template é renderizado com qualquer values
- **THEN** o `spec.template.spec.securityContext` contém `runAsNonRoot: true, runAsUser: 1997, fsGroup: 1997`

#### Scenario: Container-level securityContext

- **WHEN** o template é renderizado
- **THEN** o `spec.template.spec.containers[0].securityContext` contém `allowPrivilegeEscalation: false` e `capabilities.drop: [ALL]`

### Requirement: Escape hatches para volumes e ServiceAccount

O chart SHALL aceitar `extraVolumes` e `extraVolumeMounts` (formato nativo k8s) para casos como montar Secret de PSK em `/var/lib/zabbix/.psk`, ConfigMap com snippets em `/etc/zabbix/zabbix_proxy.d`, ou certificados TLS. O chart SHALL aceitar `serviceAccount.create/name/annotations` para suportar IRSA (AWS), Workload Identity (GCP) e similares.

#### Scenario: PSK montado via extraVolumes/extraVolumeMounts

- **WHEN** o usuário define `extraVolumes: [{name: psk, secret: {secretName: zbx-psk, items: [{key: proxy.psk, path: proxy.psk, mode: 0400}]}}]` e `extraVolumeMounts: [{name: psk, mountPath: /var/lib/zabbix/.psk, readOnly: true}]`
- **THEN** o pod monta o Secret externo no caminho indicado, sem modificar a API mínima do chart

#### Scenario: ServiceAccount criado e referenciado

- **WHEN** o usuário define `serviceAccount.create: true, serviceAccount.annotations: {eks.amazonaws.com/role-arn: arn:aws:iam::123:role/foo}`
- **THEN** um `ServiceAccount` é renderizado com a annotation
- **AND** o `serviceAccountName` do pod aponta para esse SA

### Requirement: Documentação da regra ProxyBufferMode/ProxyMemoryBufferSize

O `charts/zabbix-proxy/values.yaml` (em comentário no exemplo do `extraEnv`) e o `examples/zabbix-proxy-active.yaml` SHALL documentar que, quando `ZBX_PROXYBUFFERMODE` está em `memory` ou `hybrid`, `ZBX_PROXYMEMORYBUFFERSIZE` é obrigatório no `extraEnv`. A regra é apenas documental — o chart SHALL NOT validar isso em template nem injetar default automaticamente.

#### Scenario: values.yaml comentário cobre a regra

- **WHEN** o leitor abre `charts/zabbix-proxy/values.yaml` na seção do `extraEnv`
- **THEN** existe comentário explicando que `ZBX_PROXYBUFFERMODE in (memory, hybrid)` exige `ZBX_PROXYMEMORYBUFFERSIZE` no mesmo `extraEnv`

#### Scenario: example active demonstra o uso

- **WHEN** o leitor abre `examples/zabbix-proxy-active.yaml`
- **THEN** o `extraEnv` contém ambos `ZBX_PROXYBUFFERMODE: hybrid` e `ZBX_PROXYMEMORYBUFFERSIZE: <valor>`
- **AND** existe comentário inline explicando a regra

#### Scenario: Chart não falha render se cliente esquecer

- **WHEN** o usuário define `extraEnv: [{name: ZBX_PROXYBUFFERMODE, value: hybrid}]` sem `ZBX_PROXYMEMORYBUFFERSIZE`
- **THEN** o template renderiza com sucesso (sem `fail`)
- **AND** o pod sobe e o Zabbix Proxy falha em runtime com erro `ProxyMemoryBufferSize configuration parameter must be set` — comportamento intencional, validação fica no binário

## REMOVED Requirements

### Requirement: serverHost obrigatório

**Reason**: campo first-class `serverHost` foi removido no refactor para "plumbing-only". Cliente passa `ZBX_SERVER_HOST` via `extraEnv` com naming nativo do image.

**Migration**: substituir `serverHost: "x"` por `extraEnv: [- name: ZBX_SERVER_HOST, value: "x"]`. Sem validação `required` no chart — se ausente, o pod usa o default do image (normalmente quebra em runtime).

### Requirement: Hostname com fieldRef como default

**Reason**: campo first-class `hostname` foi removido. Cliente passa `ZBX_HOSTNAME` (com value literal ou `valueFrom.fieldRef`) via `extraEnv`.

**Migration**: substituir `hostname: ""` por `extraEnv: [- name: ZBX_HOSTNAME, valueFrom: {fieldRef: {fieldPath: metadata.name}}]`. Substituir `hostname: PROXY-X` por `extraEnv: [- name: ZBX_HOSTNAME, value: "PROXY-X"]`.

### Requirement: Modo active e passive

**Reason**: campo first-class `mode` foi removido. Cliente passa `ZBX_PROXYMODE` via `extraEnv`.

**Migration**: substituir `mode: active` por `extraEnv: [- name: ZBX_PROXYMODE, value: "0"]`. Substituir `mode: passive` por `extraEnv: [- name: ZBX_PROXYMODE, value: "1"]`.

### Requirement: TLS PSK opcional com validações

**Reason**: bloco `psk.{enabled, identity, value, existingSecret}` foi removido. PSK passa a ser configurado pelo cliente via `extraVolumes`/`extraVolumeMounts` (montagem do Secret) + `extraEnv` (`ZBX_TLSCONNECT`/`ZBX_TLSACCEPT`, `ZBX_TLSPSKIDENTITY`, `ZBX_TLSPSKFILE`).

**Migration**: ver `examples/zabbix-proxy-psk.yaml` no repositório, que demonstra o caminho completo (criar Secret, montar via `extraVolumes`, declarar envs em `extraEnv`).

### Requirement: Tunables Zabbix expostos como env

**Reason**: campos first-class `proxyBufferMode`, `timeout`, `debugLevel`, `serverPort` foram removidos. Cliente passa direto via `extraEnv` (`ZBX_PROXYBUFFERMODE`, `ZBX_TIMEOUT`, `ZBX_DEBUGLEVEL`, `ZBX_SERVER_PORT`).

**Migration**: tradução 1:1, ver tabela em `design.md > Migration Plan`.

### Requirement: Escape hatches para configs adicionais

**Reason**: requirement substituído por "Escape hatches para volumes e ServiceAccount" + "Configuração via extraEnv com naming nativo", que descrevem o mesmo conceito mas alinhados ao chart real (extraEnv não é mais "escape hatch" — é o caminho principal).

**Migration**: nenhuma — a funcionalidade continua existindo, apenas o nome e o framing do requirement mudaram.
