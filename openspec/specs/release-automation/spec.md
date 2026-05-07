# release-automation Specification

## Purpose
Automatizar validação de pull requests e publicação de charts via GitHub Actions, garantindo que cada chart seja lintado/templateado em PR e publicado em registry OCI público quando uma tag versionada for pushada.

## Requirements
### Requirement: PR validation workflow obrigatório

Todo pull request que modifica arquivos sob `charts/<chart>/` SHALL disparar um workflow GitHub Actions que executa, no mínimo, `helm lint charts/<chart>` e `helm template` sobre os arquivos `examples/<chart>-*.yaml` correspondentes (quando existirem). O workflow SHALL falhar se qualquer chart modificado falhar `lint` ou `template`.

#### Scenario: PR modifica chart-base e passa nos checks

- **WHEN** um pull request altera arquivos em `charts/chart-base/`
- **THEN** o workflow `pr-validation` é disparado
- **AND** executa `helm lint charts/chart-base` com sucesso
- **AND** executa `helm template t charts/chart-base -f examples/chart-base-deployment.yaml` e `examples/chart-base-statefulset.yaml` com sucesso
- **AND** o status do PR fica verde

#### Scenario: PR introduz template quebrado

- **WHEN** um pull request altera `charts/zabbix-proxy/templates/statefulset.yaml` introduzindo erro de sintaxe
- **THEN** o workflow `pr-validation` é disparado
- **AND** o step de `helm template` falha
- **AND** o status do PR fica vermelho, bloqueando merge (assumindo branch protection configurada)

#### Scenario: PR não altera charts

- **WHEN** um pull request altera apenas `README.md` ou `docs/`
- **THEN** o workflow `pr-validation` reconhece que nenhum chart foi modificado
- **AND** finaliza rapidamente sem rodar lint/template (evita custo desnecessário)

### Requirement: Release tag-driven com formato `<chart>-<version>`

Push de uma tag Git no formato `<chart-name>-<version>` (ex: `chart-base-0.2.0`, `zabbix-proxy-0.1.0`) SHALL disparar um workflow GitHub Actions que empacota o chart correspondente E publica no registry OCI E cria uma GitHub Release. O workflow SHALL validar que o `<chart-name>` extraído do prefixo da tag corresponde a um diretório existente em `charts/`.

#### Scenario: Tag válida dispara release

- **WHEN** alguém executa `git tag chart-base-0.2.0 && git push origin chart-base-0.2.0`
- **THEN** o workflow `release` dispara automaticamente
- **AND** identifica `chart=chart-base, version=0.2.0` pelo nome da tag
- **AND** verifica que `charts/chart-base/` existe
- **AND** verifica que `charts/chart-base/Chart.yaml` tem `version: 0.2.0` (consistência tag ↔ Chart.yaml)

#### Scenario: Tag de chart inexistente falha

- **WHEN** alguém pusha tag `chart-fantasma-0.1.0` mas `charts/chart-fantasma/` não existe
- **THEN** o workflow `release` falha cedo com mensagem clara
- **AND** nenhum push para OCI é feito
- **AND** nenhuma GitHub Release é criada

#### Scenario: Mismatch tag vs Chart.yaml falha

- **WHEN** a tag é `chart-base-0.3.0` mas `charts/chart-base/Chart.yaml` tem `version: 0.2.0`
- **THEN** o workflow falha indicando o mismatch
- **AND** nenhum push para OCI é feito

### Requirement: Push para registry OCI no `ghcr.io`

O workflow de release SHALL empacotar o chart com `helm package charts/<chart>` E autenticar em `ghcr.io` usando `GITHUB_TOKEN` E executar `helm push <chart>-<version>.tgz oci://ghcr.io/rst-services/charts`. O workflow SHALL declarar permissão `packages: write` no nível do job ou workflow.

#### Scenario: Push com sucesso

- **WHEN** o workflow de release executa para `chart-base-0.2.0`
- **THEN** após `helm package` há um arquivo `chart-base-0.2.0.tgz` no runner
- **AND** após login com `GITHUB_TOKEN`, `helm push chart-base-0.2.0.tgz oci://ghcr.io/rst-services/charts` retorna sucesso
- **AND** o package fica visível em `github.com/orgs/rst-services/packages` com nome `charts/chart-base`

#### Scenario: Permissão insuficiente

- **WHEN** o workflow não declara `permissions: packages: write`
- **THEN** o `helm push` falha com erro de autenticação
- **AND** o workflow finaliza com status falho

### Requirement: GitHub Release criada com release notes do CHANGELOG

Após push para OCI bem-sucedido, o workflow SHALL criar uma GitHub Release com tag igual à tag do release, anexar o `<chart>-<version>.tgz` como asset, E usar como corpo da release a seção do `charts/<chart>/CHANGELOG.md` correspondente à versão sendo lançada.

#### Scenario: Release notes extraídas do CHANGELOG

- **WHEN** a tag `chart-base-0.2.0` é pushada
- **AND** `charts/chart-base/CHANGELOG.md` contém uma seção `## 0.2.0` com conteúdo
- **THEN** uma GitHub Release `chart-base-0.2.0` é criada
- **AND** o corpo da release contém o texto da seção `## 0.2.0` (até a próxima `## ` ou EOF)
- **AND** o `chart-base-0.2.0.tgz` está anexado como asset

#### Scenario: CHANGELOG sem entrada para a versão

- **WHEN** a tag `chart-base-0.3.0` é pushada mas `CHANGELOG.md` não tem seção `## 0.3.0`
- **THEN** o workflow emite warning (não falha)
- **AND** a GitHub Release é criada mesmo assim com corpo padrão (ex: "Release notes pendentes")

### Requirement: Workflows declaram permissões mínimas

Os workflows SHALL declarar `permissions:` explicitamente no nível de workflow ou job, seguindo princípio de menor privilégio. PR validation usa apenas `contents: read`. Release usa `contents: write` (criar GitHub Release) E `packages: write` (push OCI). Nenhum outro escopo é concedido.

#### Scenario: PR validation com permissões reduzidas

- **WHEN** o `pr-validation.yml` é inspecionado
- **THEN** declara `permissions: { contents: read }` no nível do workflow
- **AND** não declara `packages: write` ou `id-token: write`

#### Scenario: Release com permissões mínimas necessárias

- **WHEN** o `release.yml` é inspecionado
- **THEN** declara `permissions: { contents: write, packages: write }` no nível apropriado
- **AND** não declara escopos adicionais
