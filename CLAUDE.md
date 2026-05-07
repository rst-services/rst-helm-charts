# CLAUDE.md — rst-helm-charts

Diretrizes específicas deste repositório para colaborar com o Claude Code.

## Sobre o projeto

Repositório público de charts Helm mantidos por @robertsilvatech, distribuídos como packages OCI em `oci://ghcr.io/rst-services/charts/<chart-name>`.

### Charts atuais

- **`chart-base`** (genérico): Deployment OU StatefulSet via toggle `kind`, suporta Istio VirtualService + cert-manager Certificate/Gateway. Sem opinião sobre que app está rodando.
- **`zabbix-proxy`** (opinionado): Zabbix Proxy SQLite. Plumbing-k8s + auto-injeção de pequenas peças que compensam quirks do upstream (ex.: subpasta `db_data` em emptyDir). Toda configuração do Zabbix passa via `extraEnv` com naming nativo do image.

### Arquitetura

Charts são **independentes** (não library pattern). Cada chart:
- é autocontido (helpers próprios em `_helpers.tpl`)
- é versionado independentemente em `Chart.yaml`
- é diretamente instalável via `helm install`
- tem `CHANGELOG.md` próprio

Pequena duplicação de helpers entre charts é aceitável; troca-se DRY por isolamento e simplicidade. Migrar pra library pattern só quando a duplicação começar a doer (regra: terceira repetição).

## Convenções

### Idioma

- Documentação (README, CHANGELOG, comentários) e mensagens de erro de template: **pt-BR**.
- Identificadores (variáveis, valores YAML, nomes de arquivos): **inglês**.
- Mensagens de commit e PRs: **inglês**.

### Anchor comments (AIDEV-*)

Decisões técnicas não-óbvias dentro do código devem ser marcadas com anchor comments. Eles existem pra preservar contexto que o git blame não captura.

**Prefixos:**
- `AIDEV-NOTE:` — contexto importante, decisão técnica, explicação não-óbvia
- `AIDEV-TODO:` — tarefa pendente identificada
- `AIDEV-QUESTION:` — questão aberta que precisa de resposta humana

**Regras:**
- Máx **120 caracteres por linha**.
- **Nunca** remover sem instrução explícita.
- Sintaxe por linguagem:
  - YAML/Shell: `#`
  - Markdown: `<!-- -->`
  - Helm template: `{{- /* ... */ -}}` para anchors invisíveis no render
- Buscar todos: `grep -rn "AIDEV-" .`

**Quando usar:**
- Decisão de design que tem alternativa óbvia mas pior (justificar a escolha)
- Quirk do upstream que motivou um workaround
- Invariante sutil cuja violação gera bug silencioso

**Quando NÃO usar:**
- Comentários explicando o que o código faz (use nomes melhores)
- TODO/FIXME genéricos sem contexto

### Selectors e labels Kubernetes

- Selector labels (imutáveis) são **APENAS** `app.kubernetes.io/name` + `app.kubernetes.io/instance`. Nunca `component`, `version`, etc.
- Demais labels recomendados (`helm.sh/chart`, `app.kubernetes.io/version`, `app.kubernetes.io/managed-by`, `app.kubernetes.io/component`, `app.kubernetes.io/part-of`) ficam só em `metadata.labels`.

### Charts monocomponente usam values flat

Sem wrapper redundante por nome do chart no values. Wrapper só faz sentido em umbrella charts.

### Security defaults em charts opinionados

`runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `fsGroup` correto pra imagem.

### Secrets

Use `stringData` (não `data` base64-encoded).

### Validação em template

`required "..."` em campos obrigatórios; `fail "..."` em invariantes complexas. Mensagens em pt-BR.

### Helpers padrão por chart

`<chart>.name`, `<chart>.fullname`, `<chart>.chart`, `<chart>.labels`, `<chart>.selectorLabels`, `<chart>.serviceAccountName`.

## Versionamento e release

- **SemVer** por chart, independente.
- **Tags Git**: `<chart-name>-<version>` (ex: `chart-base-0.2.0`, `zabbix-proxy-0.3.0`).
- **CHANGELOG.md por chart**, formato Keep-a-Changelog.
- **Pré-1.0**: tolerante a breaking em minor (regra do SemVer pré-1.0).
- **Pós-1.0**: breaking → bump major.

### Fluxo de release

1. PR com bump de `Chart.yaml.version` + entry no `CHANGELOG.md` da chart.
2. Merge na `main`.
3. Tag: `git tag <chart>-<version> && git push origin <chart>-<version>`.
4. Workflow `.github/workflows/release.yml` empacota e publica em `oci://ghcr.io/rst-services/charts/<chart>` + cria GitHub Release com release notes extraídas do CHANGELOG.

PR sem bump de version é OK (mudança em docs, exemplos, openspec) — só não dispara release.

## OpenSpec

Specs e changes ficam em `openspec/`. Ver `openspec/AGENTS.md` (se existir) ou rodar `openspec list` pra ver o estado atual.

- Mudanças que afetam contrato de algum chart: criar change OpenSpec antes de implementar.
- Mudanças puramente locais (typo em README, ajuste de comentário): não precisam de change.

## Estrutura do repo

```
charts/<nome>/         # cada chart isolado
examples/              # values prontos pra `helm install -f`
openspec/              # specs e changes
.github/workflows/     # PR validation + tag-driven release
README.md              # catálogo de charts
LICENSE                # Apache 2.0
```

## Diretrizes específicas para o chart `zabbix-proxy`

- **Filosofia**: chart é "plumbing-k8s + correções pontuais para quirks do upstream Zabbix". Toda configuração do proxy (envs `ZBX_*`) entra via `extraEnv` com naming nativo do image — sem aliases, sem traduções, sem campos first-class duplicando o que o image já expõe.
- **Auto-injeções aceitáveis**: ajustes que dependem só de `persistence.*` ou similares já existentes, e que corrigem comportamento documentado do upstream (ex.: `db_data` em emptyDir).
- **NÃO aceitável**: introduzir campo first-class novo só pra ZBX_* específico. Se a config se expressa como env var, fica em `extraEnv`.
