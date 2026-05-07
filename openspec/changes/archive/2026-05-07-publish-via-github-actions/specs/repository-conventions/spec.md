## MODIFIED Requirements

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
