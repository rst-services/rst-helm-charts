# repository-conventions Specification

## Purpose
TBD - created by archiving change initial-charts-baseline. Update Purpose after archive.
## Requirements
### Requirement: Charts são independentes e diretamente instaláveis

Cada chart no repositório SHALL ser autocontido (helpers próprios em `_helpers.tpl`, sem dependência de library chart) e diretamente instalável via `helm install`. Charts NÃO SHALL declarar `dependencies` em `Chart.yaml` exceto se uma dependência externa real exigir.

#### Scenario: Chart-base instalável diretamente

- **WHEN** alguém roda `helm install x charts/chart-base`
- **THEN** o `Chart.yaml` é `type: application` (ou ausente, default application)
- **AND** o chart instala com sucesso sem precisar de `helm dependency update`

#### Scenario: Zabbix-proxy instalável diretamente

- **WHEN** alguém roda `helm install x charts/zabbix-proxy --set serverHost=foo`
- **THEN** o chart instala sem dependências externas

### Requirement: SemVer por chart

Cada chart SHALL seguir SemVer (`MAJOR.MINOR.PATCH`) declarado em `Chart.yaml/version`. Mudanças breaking exigem bump major (após 1.0.0); em pré-release (0.x.y) breaking pode ocorrer em minor.

#### Scenario: Bump SemVer

- **WHEN** uma mudança breaking é introduzida em `chart-base`
- **THEN** o `version` é incrementado seguindo SemVer (major se ≥1.0.0; pode ser minor se <1.0.0)
- **AND** o `CHANGELOG.md` do chart documenta a quebra

### Requirement: CHANGELOG por chart

Cada chart SHALL ter um arquivo `charts/<nome>/CHANGELOG.md` no formato Keep-a-Changelog. Cada release versionada SHALL aparecer com seções `### Adicionado`, `### Modificado`, `### Removido`, `### Corrigido`, conforme aplicável.

#### Scenario: CHANGELOG existe e está atualizado

- **WHEN** um chart é versionado em `Chart.yaml`
- **THEN** existe `charts/<chart>/CHANGELOG.md` contendo uma seção para essa versão

### Requirement: Tags Git por chart

Releases SHALL usar tags Git no formato `<chart-name>-<version>` (ex: `chart-base-0.2.0`, `zabbix-proxy-0.1.0`). Tags SHALL ser anotadas (`git tag -a`) referenciando o commit que contém o `Chart.yaml` correspondente.

#### Scenario: Tag de release

- **WHEN** uma versão de chart é finalizada
- **THEN** uma tag Git no formato `<chart-name>-<version>` aponta para o commit que contém aquele `Chart.yaml`

### Requirement: Idioma da documentação e código

A documentação (`README.md`, `CHANGELOG.md`, comentários em `values.yaml`, `NOTES.txt`) e mensagens de erro de template (`required`, `fail`) SHALL ser em pt-BR. Identificadores YAML, nomes de variáveis, nomes de arquivos, mensagens de commit SHALL ser em inglês.

#### Scenario: Mensagem de erro de template em pt-BR

- **WHEN** uma validação `required` ou `fail` é disparada
- **THEN** a mensagem é em pt-BR (ex: `psk.enabled=true requer psk.identity`)

#### Scenario: Identificadores em inglês

- **WHEN** um chart define um helper, value key, ou nome de arquivo
- **THEN** o identificador é em inglês (ex: `serverHost`, não `hostServidor`)

### Requirement: Layout do repositório

O repositório SHALL seguir o layout:

- `charts/<nome>/` — cada chart isolado
- `examples/` — values prontos para `helm install -f`
- `openspec/` — specs e changes
- `README.md` — catálogo de charts e tabela de migração
- `LICENSE` — licença do projeto (Apache 2.0)
- `.gitignore` — padrões ignorados pelo Git (incluindo `*.tgz` de `helm package`)
- `.github/workflows/` — workflows GitHub Actions (PR validation E release tag-driven)

#### Scenario: Estrutura conformante

- **WHEN** alguém abre o repositório
- **THEN** existem os diretórios `charts/`, `examples/`, `openspec/`, `.github/workflows/`
- **AND** existe `README.md` na raiz com tabela listando os charts disponíveis
- **AND** existe `LICENSE` na raiz contendo o texto da Apache 2.0
- **AND** existe `.gitignore` na raiz cobrindo `*.tgz` E padrões comuns de OS/IDE

#### Scenario: Workflows presentes

- **WHEN** alguém abre o repositório
- **THEN** existe `.github/workflows/pr-validation.yml`
- **AND** existe `.github/workflows/release.yml`

### Requirement: Labels Kubernetes recomendados

Todo recurso renderizado por charts deste repositório SHALL incluir os labels recomendados pelo Kubernetes (`app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/version`, `app.kubernetes.io/managed-by`, `helm.sh/chart`) em `metadata.labels`. Selectors imutáveis (Deployment.spec.selector, Service.spec.selector) SHALL conter APENAS `app.kubernetes.io/name` e `app.kubernetes.io/instance`.

#### Scenario: Labels presentes em recursos

- **WHEN** qualquer chart do repositório renderiza um recurso (Deployment, StatefulSet, Service, Secret, ConfigMap, etc.)
- **THEN** o `metadata.labels` contém os 5 labels recomendados acima

#### Scenario: Selector mínimo

- **WHEN** um Deployment ou StatefulSet é renderizado
- **THEN** `spec.selector.matchLabels` tem exatamente as duas chaves: `app.kubernetes.io/name` e `app.kubernetes.io/instance`

### Requirement: Helpers padrão por chart

Cada chart SHALL definir, no mínimo, os seguintes named templates em `templates/_helpers.tpl`: `<chart>.name`, `<chart>.fullname`, `<chart>.chart`, `<chart>.labels`, `<chart>.selectorLabels`. Charts que criam `ServiceAccount` SHALL adicionalmente definir `<chart>.serviceAccountName`.

#### Scenario: Helpers existem

- **WHEN** um chart é criado neste repositório
- **THEN** o `templates/_helpers.tpl` contém pelo menos os 5 helpers obrigatórios listados

