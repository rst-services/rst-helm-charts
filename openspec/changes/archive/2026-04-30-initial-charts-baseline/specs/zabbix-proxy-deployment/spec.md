## ADDED Requirements

### Requirement: serverHost obrigatório

O chart `zabbix-proxy` SHALL falhar a renderização do template quando `serverHost` não for fornecido (string vazia ou ausente). A mensagem de erro SHALL identificar o campo (`serverHost is required`).

#### Scenario: Instalação sem serverHost falha

- **WHEN** o usuário executa `helm install` sem definir `serverHost`
- **THEN** o template render falha com erro contendo `serverHost is required`
- **AND** nenhum recurso é submetido ao cluster

#### Scenario: Instalação com serverHost prossegue

- **WHEN** o usuário define `serverHost: zbx.empresa.com`
- **THEN** o template renderiza sem erro
- **AND** o container `env` contém `{name: ZBX_SERVER_HOST, value: "zbx.empresa.com"}`

### Requirement: Hostname com fieldRef como default

Quando `hostname` não é fornecido (string vazia), o chart SHALL definir `ZBX_HOSTNAME` via `fieldRef: metadata.name`, fazendo cada pod identificar-se ao Zabbix Server pelo seu próprio nome (ordinal estável do StatefulSet).

#### Scenario: Hostname vazio usa fieldRef

- **WHEN** `hostname: ""` (default)
- **THEN** o container `env` para `ZBX_HOSTNAME` usa `valueFrom.fieldRef.fieldPath: metadata.name`

#### Scenario: Hostname customizado

- **WHEN** `hostname: PROXY-CLIENTE1`
- **THEN** o container `env` para `ZBX_HOSTNAME` é `value: "PROXY-CLIENTE1"` (não usa `fieldRef`)

### Requirement: Modo active e passive

O chart SHALL suportar `mode: active` (default) e `mode: passive`, mapeando para `ZBX_PROXYMODE=0` e `ZBX_PROXYMODE=1` respectivamente.

#### Scenario: Modo active

- **WHEN** `mode: active`
- **THEN** o container `env` contém `{name: ZBX_PROXYMODE, value: "0"}`

#### Scenario: Modo passive

- **WHEN** `mode: passive`
- **THEN** o container `env` contém `{name: ZBX_PROXYMODE, value: "1"}`

### Requirement: TLS PSK opcional com validações

Quando `psk.enabled: true`, o chart SHALL exigir `psk.identity` E (`psk.value` OU `psk.existingSecret`). Erros SHALL ser claros via `fail` em template.

Quando habilitado em modo `active`, SHALL definir `ZBX_TLSCONNECT=psk`. Em modo `passive`, SHALL definir `ZBX_TLSACCEPT=psk`. Em ambos, SHALL definir `ZBX_TLSPSKIDENTITY` e `ZBX_TLSPSKFILE=/var/lib/zabbix/.psk/proxy.psk`, e montar o arquivo PSK via Secret.

#### Scenario: PSK enabled sem identity

- **WHEN** `psk.enabled: true, psk.value: "abc"` mas `psk.identity` ausente
- **THEN** o template render falha com mensagem mencionando `psk.identity`

#### Scenario: PSK enabled sem value nem existingSecret

- **WHEN** `psk.enabled: true, psk.identity: foo` mas nem `value` nem `existingSecret` fornecidos
- **THEN** o template render falha com mensagem indicando que `psk.value` OU `psk.existingSecret` é necessário

#### Scenario: PSK active mode renderiza ZBX_TLSCONNECT

- **WHEN** `psk.enabled: true, psk.identity: id, psk.value: hex, mode: active`
- **THEN** o container `env` contém `{name: ZBX_TLSCONNECT, value: psk}` E `ZBX_TLSPSKIDENTITY=id` E `ZBX_TLSPSKFILE=/var/lib/zabbix/.psk/proxy.psk`
- **AND** existe um `Secret` no release com `stringData.proxy.psk = "hex"`
- **AND** o pod monta esse Secret em `/var/lib/zabbix/.psk` com `mode: 0400`

#### Scenario: PSK passive mode renderiza ZBX_TLSACCEPT

- **WHEN** `psk.enabled: true, psk.identity: id, psk.value: hex, mode: passive`
- **THEN** o container `env` contém `{name: ZBX_TLSACCEPT, value: psk}` (não `ZBX_TLSCONNECT`)

#### Scenario: PSK via existingSecret

- **WHEN** `psk.enabled: true, psk.identity: id, psk.existingSecret: my-psk-secret`
- **THEN** nenhum `Secret` é renderizado pelo chart (referência externa)
- **AND** o pod monta `secretName: my-psk-secret` em `/var/lib/zabbix/.psk`

### Requirement: Persistência por pod via volumeClaimTemplates

O chart SHALL renderizar SEMPRE como `StatefulSet` com `spec.volumeClaimTemplates[0]` chamado `data`, com tamanho `persistence.size` (default `5Gi`), `persistence.accessMode` (default `ReadWriteOnce`), e opcionalmente `persistence.storageClass`. O container SHALL montar `data` em `/var/lib/zabbix`.

#### Scenario: Persistence default

- **WHEN** o usuário não toca em `persistence`
- **THEN** o StatefulSet tem `volumeClaimTemplates[0]` com `name: data, accessModes: [ReadWriteOnce], resources.requests.storage: 5Gi`
- **AND** o container monta `data` em `/var/lib/zabbix`

#### Scenario: StorageClass custom

- **WHEN** `persistence.storageClass: gp3`
- **THEN** o `volumeClaimTemplates[0].spec.storageClassName` é `"gp3"`

### Requirement: Security defaults non-root

O pod SHALL rodar com `runAsNonRoot: true, runAsUser: 1997, fsGroup: 1997` (alinhado ao usuário `zabbix` da imagem oficial). O container SHALL ter `allowPrivilegeEscalation: false` e `capabilities.drop: [ALL]`.

#### Scenario: Pod-level securityContext

- **WHEN** o template é renderizado com qualquer values
- **THEN** o `spec.template.spec.securityContext` contém `runAsNonRoot: true, runAsUser: 1997, fsGroup: 1997`

#### Scenario: Container-level securityContext

- **WHEN** o template é renderizado
- **THEN** o `spec.template.spec.containers[0].securityContext` contém `allowPrivilegeEscalation: false` e `capabilities.drop: [ALL]`

### Requirement: Tunables Zabbix expostos como env

O chart SHALL expor tunables Zabbix `proxyBufferMode` (default `hybrid`), `timeout` (default `30`), `debugLevel` (default `3`), e `serverPort` (default `10051`) traduzindo-os respectivamente para os envs `ZBX_PROXYBUFFERMODE`, `ZBX_TIMEOUT`, `ZBX_DEBUGLEVEL`, `ZBX_SERVER_PORT`.

#### Scenario: Defaults aplicados

- **WHEN** o usuário não muda esses valores
- **THEN** o container env contém `ZBX_PROXYBUFFERMODE=hybrid, ZBX_TIMEOUT=30, ZBX_DEBUGLEVEL=3, ZBX_SERVER_PORT=10051`

#### Scenario: Override de timeout

- **WHEN** o usuário define `timeout: 60`
- **THEN** o container env contém `ZBX_TIMEOUT=60`

### Requirement: Service ClusterIP na porta 10051

O chart SHALL renderizar um Service tipo `ClusterIP` (default) expondo a porta 10051 com targetPort nomeada `zbx-proxy`.

#### Scenario: Service default

- **WHEN** o usuário não toca em `service`
- **THEN** existe um `Service` com `type: ClusterIP, ports[0].port: 10051, targetPort: zbx-proxy`

### Requirement: Escape hatches para configs adicionais

O chart SHALL aceitar `extraEnv`, `extraVolumes`, `extraVolumeMounts` para casos não cobertos pela API mínima (ex: ConfigMap externo com snippets em `/etc/zabbix/zabbix_proxy.d`, integração com Vault).

#### Scenario: ConfigMap snippets via extraVolumes

- **WHEN** o usuário define `extraVolumes: [{name: snippets, configMap: {name: my-snippets}}]` e `extraVolumeMounts: [{name: snippets, mountPath: /etc/zabbix/zabbix_proxy.d, readOnly: true}]`
- **THEN** o pod monta o ConfigMap externo no caminho indicado, sem modificar a API mínima do chart
