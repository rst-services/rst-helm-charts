# Changelog — zabbix-proxy

## 0.2.0

Republicação do chart com o contrato definitivo "plumbing-only" (`extraEnv`-based) e documentação da regra `ProxyMemoryBufferSize`.

> **Nota sobre `0.1.0`**: o package `oci://ghcr.io/rst-services/charts/zabbix-proxy:0.1.0` foi publicado **antes** do refactor para "plumbing-only" e tem schema first-class antigo (`serverHost`, `mode`, `psk`, `proxyBufferMode`, ...) que diverge do `0.1.0` versionado neste repositório. A versão `0.2.0` substitui esse `0.1.0` divergente como **contrato definitivo** — daqui em diante, conteúdo no GHCR e no repo coincidem por tag.

### Adicionado

- Documentação no `values.yaml` (comentário no exemplo do `extraEnv`) explicando que `ZBX_PROXYBUFFERMODE` em `memory` ou `hybrid` exige `ZBX_PROXYMEMORYBUFFERSIZE` no mesmo `extraEnv`. Sem essa env o pod sobe e morre com `ProxyMemoryBufferSize configuration parameter must be set`.
- `examples/zabbix-proxy-active.yaml` agora declara `ZBX_PROXYMEMORYBUFFERSIZE: "256M"` ao lado do `ZBX_PROXYBUFFERMODE: hybrid`.

### Mudado

- **BREAKING (vs `0.1.0` publicado no GHCR)** — toda configuração do Zabbix Proxy passa exclusivamente por `extraEnv` com naming nativo do image. Campos first-class do `0.1.0` antigo foram removidos: `serverHost`, `hostname`, `mode`, `psk.*`, `proxyBufferMode`, `timeout`, `debugLevel`, `serverPort`. Tabela de migração:

  | Antigo (`0.1.0` GHCR)                | Novo (`0.2.0`, via `extraEnv`)                                                       |
  |--------------------------------------|--------------------------------------------------------------------------------------|
  | `serverHost: "x"`                    | `- name: ZBX_SERVER_HOST` / `value: "x"`                                             |
  | `hostname: ""`                       | `- name: ZBX_HOSTNAME` / `valueFrom.fieldRef.fieldPath: metadata.name`               |
  | `hostname: "PROXY-X"`                | `- name: ZBX_HOSTNAME` / `value: "PROXY-X"`                                          |
  | `mode: active` / `mode: passive`     | `- name: ZBX_PROXYMODE` / `value: "0"` (active) ou `"1"` (passive)                   |
  | `proxyBufferMode: hybrid`            | `- name: ZBX_PROXYBUFFERMODE` / `value: "hybrid"` + **`ZBX_PROXYMEMORYBUFFERSIZE`**  |
  | `timeout: 30`                        | `- name: ZBX_TIMEOUT` / `value: "30"`                                                |
  | `debugLevel: 3`                      | `- name: ZBX_DEBUGLEVEL` / `value: "3"`                                              |
  | `serverPort: 10051`                  | `- name: ZBX_SERVER_PORT` / `value: "10051"`                                         |
  | `psk.enabled` + `psk.identity/value` | `extraVolumes` montando Secret PSK + `ZBX_TLSCONNECT/TLSPSKIDENTITY/TLSPSKFILE`      |

  Veja `examples/zabbix-proxy-active.yaml` e `examples/zabbix-proxy-psk.yaml` para snippets completos.

### Migração rápida

Para clientes em ArgoCD apontando para `targetRevision: 0.1.0`:

1. Trocar `targetRevision: 0.1.0 → 0.2.0`.
2. Migrar `valuesObject` para o esquema `extraEnv` (tabela acima).
3. Se usar `ZBX_PROXYBUFFERMODE` em `memory` ou `hybrid`, adicionar `ZBX_PROXYMEMORYBUFFERSIZE` (ex: `"256M"`).

## 0.1.0

Primeira release. Substitui o repositório [helm-zabbix-proxy](https://github.com/robertsilvatech/helm-zabbix-proxy) (deprecado).

> **Distribuição**: chart publicado como package OCI público em `oci://ghcr.io/rst-services/charts/zabbix-proxy` — `helm install` direto, sem auth.

### Filosofia

Chart é **plumbing k8s puro** (StatefulSet + Service + PVC opcional). Toda configuração do Zabbix Proxy (variáveis `ZBX_*`) passa exclusivamente por `extraEnv` — sem aliases, sem traduções, naming nativo do image `zabbix/zabbix-proxy-sqlite3`.

### Recursos

- StatefulSet com identidade estável (StatefulSet ordinal pro SQLite buffer). Nome do StatefulSet/Service/Pod = release name diretamente (em vez do padrão Bitnami `<release>-<chart>`), gerando pods curtos `<release>-0`, `<release>-1`. Combinado com `ZBX_HOSTNAME` via `fieldRef.metadata.name`, cada pod se registra no Zabbix Server com seu nome curto e único.
- Persistência opcional via `persistence.enabled` (default `true`, PVC por pod). Quando `false`, `/var/lib/zabbix` vira `emptyDir` (uso em dev/teste).
- Toda config do proxy via `extraEnv` — chaves seguem naming nativo do image (`ZBX_HOSTNAME`, `ZBX_SERVER_HOST`, `ZBX_PROXYMODE`, `ZBX_TLSCONNECT`, etc).
- `extraVolumes`/`extraVolumeMounts` pra montar Secret de PSK, snippets em `/etc/zabbix/zabbix_proxy.d`, certificados, etc.
- Service ClusterIP na porta 10051, com toggle `service.headless` pra DNS por pod.
- Suporte a `serviceAccount.create/name/annotations` (IRSA, Workload Identity).
- Defaults seguros: `runAsNonRoot`, `fsGroup: 1997`, `capabilities.drop: [ALL]`, `allowPrivilegeEscalation: false`.
- App version pinada em Zabbix LTS 7.0.16 (`appVersion`). Image default `zabbix/zabbix-proxy-sqlite3:ubuntu-7.0-latest` — sobrescreva `image.tag` pra usar current (ex: `ubuntu-7.4-latest`).
- NOTES.txt com próximos passos pós-instalação.
