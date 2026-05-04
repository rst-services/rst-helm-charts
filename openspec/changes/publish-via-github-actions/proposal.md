## Why

Os dois charts (`chart-base` 0.2.0 e `zabbix-proxy` 0.1.0) estão prontos mas só instaláveis via path local — clientes não têm como consumir. Sem pipeline de release, cada nova versão exigiria steps manuais propensos a erro (esquecer de empacotar, esquecer de criar release, mismatch entre tag e Chart.yaml). Esta change estabelece a infraestrutura de release automática (validação de PR + push para registry OCI no `ghcr.io`) e documenta como clientes autenticam e instalam.

## What Changes

- **Adiciona `LICENSE`** (Apache 2.0) na raiz do repositório.
- **Adiciona `.gitignore`** na raiz (cobrindo `*.tgz` de helm package, OS files, IDE configs).
- **Adiciona `.github/workflows/pr-validation.yml`**: dispara em pull requests, detecta charts modificados (via `git diff` no `charts/`), executa `helm lint` e `helm template` sobre os examples relacionados.
- **Adiciona `.github/workflows/release.yml`**: dispara em push de tags no formato `<chart>-<version>` (ex: `chart-base-0.2.0`). Empacota o chart correspondente, autentica no `ghcr.io` via `GITHUB_TOKEN`, faz `helm push` para `oci://ghcr.io/rst-services/charts`, e cria GitHub Release com o `.tgz` anexado e a seção do `CHANGELOG` correspondente como release notes.
- **Atualiza `README.md`** raiz com instruções de install via OCI (incluindo `helm registry login`), aviso sobre packages privados (PAT necessário), e link para o documento de onboarding.
- **Adiciona `docs/onboarding-cliente.md`** com passo-a-passo manual: criar PAT no GitHub (scope `read:packages`, expiração 90 dias), `helm registry login ghcr.io`, primeiro install, e procedimento de rotação.

Sem mudanças nos charts (`chart-base`, `zabbix-proxy`) ou specs existentes deles.

## Capabilities

### New Capabilities

- `release-automation`: contrato de como charts são validados em pull requests e publicados via tag-driven release. Cobre: validação obrigatória em PR (lint + template), formato de tag `<chart>-<version>`, push para OCI no `ghcr.io`, criação de GitHub Release com release notes derivadas do `CHANGELOG`.

- `client-installation`: contrato de como clientes autenticam e instalam charts publicados. Cobre: localização canônica `oci://ghcr.io/rst-services/charts/<chart>`, autenticação via PAT individual (Padrão 2 — bot user por cliente), scope mínimo (`read:packages`), comandos de install documentados em `docs/onboarding-cliente.md`.

### Modified Capabilities

- `repository-conventions`: adiciona requirements sobre arquivos obrigatórios na raiz (`LICENSE`, `.gitignore`), pasta `.github/workflows/` com os dois workflows definidos por `release-automation`, e `docs/onboarding-cliente.md` referenciado por `client-installation`.

## Impact

- **Novos arquivos**: `LICENSE`, `.gitignore`, `.github/workflows/pr-validation.yml`, `.github/workflows/release.yml`, `docs/onboarding-cliente.md`.
- **Arquivo modificado**: `README.md` (seção de instalação substituída).
- **Charts existentes**: NÃO tocados.
- **APIs públicas dos charts**: nenhuma alteração.
- **Dependências externas**:
  - GitHub Container Registry (`ghcr.io`) como registry OCI de Helm charts.
  - Permissão `packages: write` no workflow de release (declarada via `permissions:` no YAML, sem setup manual fora do repo).
  - GitHub Actions runners (`ubuntu-latest`).
- **Permissões/secrets**: `GITHUB_TOKEN` injetado automaticamente pelo Actions; nenhum secret manual necessário no escopo desta change.
- **Custo**: GitHub Actions free tier suficiente; `ghcr.io` packages privados são gratuitos sem limite operacional para Helm charts.
- **Operação humana após merge**: criar tags `chart-base-0.2.0` e `zabbix-proxy-0.1.0` para disparar o primeiro release oficial dos charts (item nas tasks).
- **Mudança breaking**: nenhuma.
