## Why

O repositório `rst-helm-charts` foi construído antes da adoção do OpenSpec; precisamos formalizar o estado atual como baseline pra que mudanças futuras tenham contrato explícito contra o qual evoluir. Sem essa baseline, próximas changes não conseguem expressar deltas (modificações ou remoções) sobre specs inexistentes.

## What Changes

- Estabelece a estrutura inicial do repositório: `charts/`, `examples/`, `openspec/`, `README.md`.
- Adiciona o chart `chart-base` 0.2.0: chart genérico para Deployment OU StatefulSet, com Istio + cert-manager opcionais e primitivos production-ready (security context, scheduling, image digest, secret stringData).
- Adiciona o chart `zabbix-proxy` 0.1.0: chart opinionado para Zabbix Proxy SQLite com API flat e mínima (`serverHost`, `hostname`, `mode`, PSK opcional). Substitui o repositório legado `helm-zabbix-proxy` (deprecado).
- Adiciona exemplos de values em `examples/` para os dois charts.
- Documenta convenções transversais do repositório: charts independentes (não library), values flat em charts monocomponente, security defaults non-root, labels k8s recomendados, SemVer por chart, idioma pt-BR na documentação.

Não há mudanças breaking porque é a primeira release; tudo é "novo".

## Capabilities

### New Capabilities
- `generic-workload-chart`: contrato do chart `chart-base` — gera workload (Deployment ou StatefulSet via toggle `kind`) com primitivos completos para apps stateless e stateful em produção, incluindo Istio + cert-manager opcionais.
- `zabbix-proxy-deployment`: contrato do chart `zabbix-proxy` — provê Zabbix Proxy SQLite production-ready com API mínima por cliente, persistência por pod (PVC via `volumeClaimTemplates`), TLS PSK opcional, e defaults seguros alinhados ao usuário Zabbix da imagem oficial.
- `repository-conventions`: convenções transversais que TODOS os charts deste repositório seguem — labels k8s, selector imutável, naming, SemVer por chart, idioma da documentação, layout do repo.

### Modified Capabilities
<!-- Nenhuma. Esta é a primeira change; não há specs prévias para modificar. -->

## Impact

- **Código**: cria toda a estrutura do repositório do zero — dois charts em `charts/`, exemplos em `examples/`.
- **APIs públicas (values dos charts)**:
  - `chart-base` expõe API rica (~30 chaves top-level): `kind`, `image`, `service`, `serviceAccount`, `env`/`envFrom`, `extraVolumes`, `podSecurityContext`, `securityContext`, `tolerations`, `affinity`, `topologySpreadConstraints`, `priorityClassName`, `persistentVolume`, `statefulSet`, `virtualService`, etc.
  - `zabbix-proxy` expõe API mínima e flat (~15 chaves top-level): `serverHost` (required), `hostname`, `mode`, `serverPort`, `psk`, `persistence`, `image`, `service`, `resources`, etc.
- **Dependências externas**: nenhuma (charts não declaram `dependencies` em `Chart.yaml`).
- **Sistemas**: substitui o repositório legado [helm-zabbix-proxy](https://github.com/robertsilvatech/helm-zabbix-proxy), que deve ser marcado como deprecado em change posterior.
- **Publicação**: NÃO inclui setup de publicação no GitHub Pages / OCI. Isso vira change separada.
- **CI/CD**: NÃO inclui workflows de lint/test automatizados ainda.
