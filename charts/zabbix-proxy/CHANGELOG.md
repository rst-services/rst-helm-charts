# Changelog — zabbix-proxy

## 0.1.0

Primeira release. Substitui o repositório [helm-zabbix-proxy](https://github.com/robertsilvatech/helm-zabbix-proxy) (deprecado).

> **Distribuição**: chart publicado como package OCI público em `oci://ghcr.io/rst-services/charts/zabbix-proxy` — `helm install` direto, sem auth.

### Adicionado

- StatefulSet com `volumeClaimTemplates` (PVC por pod, identidade estável pro SQLite).
- API mínima e flat: `serverHost` (obrigatório), `hostname`, `mode` (active/passive), `serverPort`.
- TLS PSK opcional (`psk.{enabled,identity,value,existingSecret}`).
- Persistência configurável (`persistence.{size,storageClass,accessMode}`).
- `extraEnv`, `extraVolumes`, `extraVolumeMounts` como escape hatches.
- Defaults seguros: `runAsNonRoot`, `fsGroup: 1997`, `capabilities.drop: [ALL]`, `allowPrivilegeEscalation: false`.
- Validações em template: serverHost obrigatório; PSK enabled exige identity + (value ou existingSecret).
- NOTES.txt com próximos passos pós-instalação.
- Service ClusterIP na porta 10051, com toggle `service.headless`.
- Suporte a `serviceAccount.create/name/annotations` (IRSA, Workload Identity).
- App version pinada em Zabbix LTS 7.0.16 (`appVersion`).
- Imagem default `zabbix/zabbix-proxy-sqlite3:ubuntu-7.0-latest`.
