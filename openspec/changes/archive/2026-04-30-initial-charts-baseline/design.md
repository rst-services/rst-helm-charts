## Context

Esta é a baseline do repositório `rst-helm-charts`. O autor já mantinha:

- `helm-zabbix-proxy` (chart antigo, simples mas com bugs e sem persistência)
- `chart-base` 0.1.4 (interno, em GitLab Sanasa, usado em produção pra apps de cliente)

Decidimos consolidar tudo num repo único e público, com dois charts iniciais. As decisões arquiteturais documentadas aqui foram tomadas em sessão de design antes de invocar o OpenSpec — esta change as formaliza retroativamente.

## Goals / Non-Goals

**Goals:**

- Estabelecer dois charts publicáveis (`chart-base`, `zabbix-proxy`) como ponto de partida.
- Travar convenções transversais antes do repo crescer (labels, naming, SemVer, idioma).
- Substituir o `helm-zabbix-proxy` legado por chart opinionado dentro deste repo.
- Permitir que clientes do autor (que usavam o `chart-base 0.1.x` interno) migrem com mudança mínima.

**Non-Goals:**

- Library chart pattern (`type: library`) — adiada até houver duplicação dolorosa entre 3+ charts.
- Publicação no GitHub Pages / OCI — change separada (`publish-to-github`).
- HPA, PodDisruptionBudget, NetworkPolicy — backlog do `chart-base 0.3.0`.
- `values.schema.json`, `helm-docs`, testes automatizados (`ct lint/install`) — backlog.
- Suporte a Postgres/MySQL backend no `zabbix-proxy` — apenas SQLite por ora.
- Outros componentes do stack Zabbix (Server, Agent, Web) — fora de escopo, foco é Proxy.

## Decisions

### D1. Charts independentes em vez de library + opinionated

Cada chart tem seus próprios helpers, templates e values. Sem `type: library` compartilhada.

**Rationale**: `chart-base` precisa ser publicamente instalável (`helm install rst/chart-base ...`), o que `type: library` impede. Alternativas consideradas:

- **Library + 2 application wrappers (estilo Bitnami common)**: dá 3 charts no repo (1 não-instalável "interno"). Mais setup, mais ferramentas (`helm dependency update` em CI), e o "_chart-base-lib" confunde quem chega. Rejeitada por overhead pra escala atual (2-3 charts).
- **Sub-chart dependency (`Chart.yaml: dependencies:`)**: a tradução de values do parent (zabbix-proxy) pra o sub-chart (chart-base) é estática no Helm, exigindo gambiarras (ConfigMap intermediário) pra valores dinâmicos. Rejeitada por awkwardness.
- **Charts independentes (escolhida)**: alguma duplicação de helpers (~30 linhas) é o preço. Cada chart evolui no seu ritmo, sem coupling. Migrar pra library depois é fácil; o caminho inverso é difícil.

Regra de gatilho pra reavaliar: quando a duplicação aparecer pela **terceira vez** em charts diferentes, extrair pra library.

### D2. Toggle `kind: Deployment | StatefulSet` no chart-base

Template unificado em `templates/workload.yaml` que renderiza Deployment ou StatefulSet conforme `.Values.kind`.

**Rationale**: Permite cobrir apps stateless e stateful com um chart só. Alternativas:

- **Templates separados (`deployment.yaml`, `statefulset.yaml`) com `if`**: duplica boilerplate (selector, podSpec, containers idênticos). Rejeitada.
- **Detectar automaticamente pelo presença de `volumeClaimTemplates`**: magia demais. Usuário não entende quando vira StatefulSet. Rejeitada.
- **Sempre StatefulSet**: overkill pra app web. Rejeitada.
- **Toggle explícito (escolhida)**: usuário declara intent claramente; um template só.

### D3. Values flat (sem wrapper) em charts monocomponente

`zabbix-proxy/values.yaml` tem `serverHost:` no top-level, não `zabbixProxy.serverHost`.

**Rationale**: O nome do chart já é o namespace. Wrapper `zabbixProxy:` seria redundante. Charts da comunidade que usam wrapper (helm-zabbix oficial) são umbrellas com múltiplos componentes (`zabbixServer:`, `zabbixProxy:`, `zabbixAgent:`) — essa é a única razão pra wrapping.

Se algum chart deste repo virar umbrella no futuro, voltamos a usar wrapper *naquele* chart.

### D4. Selector labels apenas `app.kubernetes.io/name` + `/instance`

Sem `component`, `version`, ou outros no `selector.matchLabels`.

**Rationale**: Selector é **imutável** em Deployment/StatefulSet. Adicionar campos lá hoje cria dor amanhã (qualquer change que mexa no campo exige `helm uninstall`+`install`, não `helm upgrade`). Conforme [k8s docs](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#selector). Outros labels informativos vão pro `metadata.labels` do pod, sem entrar no selector.

### D5. Security defaults non-root em charts opinionados

`zabbix-proxy` aplica `runAsNonRoot: true`, `runAsUser/fsGroup: 1997` (zabbix user), `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]` por default.

**Rationale**: PodSecurityAdmission (PSA) é a norma em clusters modernos; default inseguro força usuário a configurar manualmente. Charts opinionados existem justamente pra trazer defaults bons.

`chart-base` (genérico) NÃO impõe defaults — deixa `securityContext: {}` vazio porque imagem genérica pode não rodar non-root. Usuário é responsável.

### D6. Validação em template via `required` + `fail`

`zabbix-proxy` valida em template:
- `serverHost` obrigatório (`required "serverHost is required"`)
- Se `psk.enabled`, exige `psk.identity` + (`psk.value` OU `psk.existingSecret`) (`fail` com mensagem clara)

**Rationale**: Falha cedo, com mensagem em português, antes do `kubectl apply` quebrar com erro críptico. Alternativas:

- **`values.schema.json`**: melhor UX (validação antes do template render), mas custo de manter à mão. Pode ser adicionado em `0.2.0`.
- **Sem validação**: usuário descobre o erro só quando o pod tenta subir. Rejeitada.

### D7. Idioma: documentação em pt-BR, código em inglês

README, CHANGELOG, comentários em values, mensagens de `required`/`fail`: pt-BR.
Identificadores YAML, nomes de variáveis, commits, nomes de arquivos: inglês.

**Rationale**: Audiência primária é o autor + clientes brasileiros. Inglês em identificadores preserva interop com tooling helm/k8s e potenciais contribuidores externos.

## Risks / Trade-offs

- **Duplicação de helpers entre charts** → Mitigation: monitorar; se aparecer pela 3ª vez, extrair pra library.
- **Charts ainda não testados em produção pública** → Mitigation: validações via `helm lint` + `helm template` em múltiplos cenários (cobertas em `tasks.md`); testes em cluster de staging antes de v1.0.
- **`chart-base` 0.2.0 introduz breaking change implícito** vs versão interna 0.1.4 (selector labels mudaram, fullname helper aplicado em mais lugares) → Mitigation: documentado em `charts/chart-base/CHANGELOG.md`; clientes existentes precisam de `helm uninstall`+`install`.
- **Substituição do `helm-zabbix-proxy` legado** → Mitigation: tabela de migração no README do repo. Repo legado deve ser marcado deprecado em change separada.
- **OpenSpec adotado retroativamente** → Mitigation: esta própria change formaliza tudo; futuras mudanças seguem o fluxo normal `propose → apply → archive`.

## Migration Plan

Não há sistema rodando hoje pra migrar — esta é a primeira release. Para clientes vindos de:

- **`helm-zabbix-proxy` (repo legado)**: trocar para `helm install rst/zabbix-proxy` com a tabela de equivalência no README.
- **`chart-base 0.1.x` (interno GitLab Sanasa)**: `helm uninstall` + `helm install` (selector labels mudaram). Releases existentes não têm upgrade in-place.

Rollback: como esta é a release inicial, "rollback" significa apenas `helm uninstall` se a instalação não funcionar.

## Open Questions

- **Publicação**: usar `chart-releaser-action` + GitHub Pages, OCI no `ghcr.io`, ou ambos? → resolver em change `publish-to-github`.
- **Suporte a Zabbix 6.0 LTS**: cliente legado pode pedir. Avaliar quando aparecer; possivelmente segundo chart `zabbix-proxy-6` ou tag de imagem configurável já cobre.
- **`values.schema.json`**: vale o investimento agora ou só após primeiros usuários reportarem confusão? → backlog.
