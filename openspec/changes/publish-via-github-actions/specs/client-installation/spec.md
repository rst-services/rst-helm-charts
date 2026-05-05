## ADDED Requirements

### Requirement: Localização canônica dos charts publicados

Charts deste repositório SHALL ser publicados em `oci://ghcr.io/rst-services/charts/<chart-name>` como packages OCI públicos. Não há localização alternativa autorizada (sem GitHub Pages, sem mirror em outros registries) nesta versão.

#### Scenario: Localização correta após primeiro release

- **WHEN** o primeiro release de `chart-base` 0.2.0 completa
- **THEN** o package está acessível em `oci://ghcr.io/rst-services/charts/chart-base` versão `0.2.0`
- **AND** a visibilidade do package é "public" no GitHub (`github.com/orgs/rst-services/packages/container/charts%2Fchart-base`)

### Requirement: Install sem autenticação

A instalação de qualquer chart deste repositório SHALL ser possível sem `helm registry login` ou credenciais. O `helm pull`/`helm install` anônimo SHALL funcionar contra o OCI público.

#### Scenario: Cliente instala sem login

- **WHEN** o cliente executa `helm install zbx oci://ghcr.io/rst-services/charts/zabbix-proxy --version 0.1.0 -f my-values.yaml` sem ter feito `helm registry login`
- **THEN** o chart é puxado do GHCR público
- **AND** instalado no cluster

### Requirement: README raiz documenta install OCI

O `README.md` na raiz do repositório SHALL conter uma seção "Instalação" que:

1. Indica que packages são públicos.
2. Mostra fluxo direto `helm install oci://...` sem login.

A seção SHALL substituir qualquer instrução anterior baseada em path local (`./charts/<chart>`) ou GitHub Pages.

#### Scenario: README atualizado

- **WHEN** o `README.md` é renderizado
- **THEN** contém uma seção "Instalação" com:
  - Indicação de que packages são públicos
  - Bloco de comando com `helm install oci://ghcr.io/rst-services/charts/<chart> --version <version>`
- **AND** não menciona `helm registry login` como passo obrigatório
- **AND** não menciona `helm repo add` para GitHub Pages (não é o método autorizado)
