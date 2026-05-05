# rst-helm-charts

Helm charts mantidos por [@robertsilvatech](https://github.com/robertsilvatech), distribuídos como packages OCI privados em `ghcr.io/rst-services/charts`.

## Charts

| Chart | Versão | App | Descrição |
|-------|--------|-----|-----------|
| [chart-base](charts/chart-base) | 0.2.0 | — | Chart genérico para workloads stateless (Deployment) e stateful (StatefulSet), com suporte opcional a Istio + cert-manager. |
| [zabbix-proxy](charts/zabbix-proxy) | 0.1.0 | Zabbix 7.0.16 LTS | Chart de plumbing k8s para Zabbix Proxy SQLite. StatefulSet + Service + PVC opcional. Toda config do proxy via `extraEnv`. Suporta Zabbix 7.0 LTS (default) ou 7.4 current via override de `image.tag`. |

## Instalação

Packages são públicos — `helm install` direto, sem login.

```bash
# Install (chart genérico)
helm install minha-api oci://ghcr.io/rst-services/charts/chart-base \
  --version 0.2.0 \
  -f my-values.yaml

# Install (Zabbix Proxy) — config via values
helm install zbx-cliente1 oci://ghcr.io/rst-services/charts/zabbix-proxy \
  --version 0.1.0 \
  -f my-zabbix-values.yaml
```

## Examples

| Arquivo | O que demonstra |
|---|---|
| [chart-base-deployment.yaml](examples/chart-base-deployment.yaml) | App stateless de cliente (Deployment + Service + probes + securityContext). |
| [chart-base-statefulset.yaml](examples/chart-base-statefulset.yaml) | StatefulSet genérico com PVC por pod (ex: Redis). |
| [zabbix-proxy-active.yaml](examples/zabbix-proxy-active.yaml) | Zabbix Proxy ativo — config via `extraEnv`. |
| [zabbix-proxy-psk.yaml](examples/zabbix-proxy-psk.yaml) | Zabbix Proxy com TLS PSK — Secret montado via `extraVolumes`, envs via `extraEnv`. |

## Convenções

- Labels seguem [Kubernetes recommended labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/).
- Selectors (imutáveis) são apenas `app.kubernetes.io/name` + `app.kubernetes.io/instance`.
- Cada chart é **autocontido** e versionado independentemente. Mudanças num chart não exigem bump dos outros.
- Specs e change history versionados em [`openspec/`](openspec/) (workflow [OpenSpec](https://github.com/Fission-AI/OpenSpec)).

## Migração do helm-zabbix-proxy → zabbix-proxy

O repositório [helm-zabbix-proxy](https://github.com/robertsilvatech/helm-zabbix-proxy) está deprecado. Equivalência de values:

| helm-zabbix-proxy 1.0.0 | zabbix-proxy 0.1.0 |
|--|--|
| `image.repository/tag/imagePullPolicy` | `image.repository/tag/pullPolicy` |
| (hardcoded) `ZBX_HOSTNAME = upper(Release.Name)` | `extraEnv: [{name: ZBX_HOSTNAME, valueFrom: {fieldRef: {fieldPath: metadata.name}}}]` |
| (hardcoded) `ZBX_SERVER_HOST = zbx-server-mysql-service` | `extraEnv: [{name: ZBX_SERVER_HOST, value: ...}]` |
| `service.port/targetPort` | `service.port` (target sempre `zbx-proxy`) |
| (sem persistência) | `persistence.{enabled,size,storageClass,accessMode}` (PVC por pod, padrão 5Gi) |
| (sem PSK) | Secret + `extraVolumes`/`extraVolumeMounts` + envs via `extraEnv` |
| (sem securityContext) | `runAsNonRoot:true`, `fsGroup:1997`, `drop: [ALL]` por padrão |

## Bumping & release

- Cada `charts/<nome>/Chart.yaml` é versionado independentemente (SemVer).
- Mudança breaking → bump major do chart afetado, documentar em `charts/<nome>/CHANGELOG.md`.
- Releases são tags Git no formato `<chart-name>-<version>` (ex: `chart-base-0.2.0`, `zabbix-proxy-0.1.0`).
- Push de tag dispara automaticamente o workflow [`.github/workflows/release.yml`](.github/workflows/release.yml), que empacota o chart, publica em `oci://ghcr.io/rst-services/charts/<chart>` e cria GitHub Release com release notes vindas da seção do `CHANGELOG.md`.

## Workflows

- [`pr-validation.yml`](.github/workflows/pr-validation.yml) — `helm lint` + `helm template` em todos os examples dos charts modificados em PRs.
- [`release.yml`](.github/workflows/release.yml) — package + push OCI + GitHub Release em push de tag `<chart>-<version>`.

## Licença

Apache 2.0 — veja [LICENSE](LICENSE).
