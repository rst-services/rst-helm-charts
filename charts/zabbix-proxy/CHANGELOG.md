# Changelog — zabbix-proxy

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
