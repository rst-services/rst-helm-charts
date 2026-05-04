## ADDED Requirements

### Requirement: Localização canônica dos charts publicados

Charts deste repositório SHALL ser publicados em `oci://ghcr.io/rst-services/charts/<chart-name>` como packages OCI privados. Não há localização alternativa autorizada (sem GitHub Pages, sem mirror em outros registries) nesta versão.

#### Scenario: Localização correta após primeiro release

- **WHEN** o primeiro release de `chart-base` 0.2.0 completa
- **THEN** o package está acessível em `oci://ghcr.io/rst-services/charts/chart-base` versão `0.2.0`
- **AND** a visibilidade do package é "private" no GitHub (`github.com/orgs/rst-services/packages/container/charts%2Fchart-base`)

### Requirement: Autenticação obrigatória via PAT (Padrão 2)

A instalação de qualquer chart deste repositório SHALL exigir autenticação prévia em `ghcr.io` via `helm registry login`. O cliente SHALL usar um Personal Access Token (PAT) fine-grained do GitHub com scope mínimo `read:packages` E expiração máxima de 90 dias. Cada cliente SHALL ter um bot user GitHub dedicado (`rst-bot-cliente<N>`) — credenciais NÃO são compartilhadas entre clientes.

#### Scenario: Cliente autentica e instala com sucesso

- **WHEN** o cliente recebeu seu bot user (`rst-bot-cliente1`) e PAT (`ghp_xxxxx`)
- **AND** executa `echo $PAT | helm registry login ghcr.io -u rst-bot-cliente1 --password-stdin`
- **AND** executa `helm install zbx oci://ghcr.io/rst-services/charts/zabbix-proxy --version 0.1.0 -f my-values.yaml`
- **THEN** o login retorna sucesso
- **AND** o chart é puxado e instalado no cluster do cliente

#### Scenario: Cliente sem PAT falha cedo

- **WHEN** o cliente tenta `helm install oci://ghcr.io/rst-services/charts/chart-base --version 0.2.0` sem ter feito login
- **THEN** o `helm install` falha com erro de autenticação
- **AND** nenhum recurso é submetido ao cluster

#### Scenario: PAT expirado falha

- **WHEN** o PAT do cliente expirou
- **THEN** `helm install` falha com erro de autenticação no pull
- **AND** o cliente é orientado pelo erro a renovar PAT seguindo `docs/onboarding-cliente.md`

### Requirement: Documento de onboarding obrigatório

O repositório SHALL conter `docs/onboarding-cliente.md` com instruções suficientes para um operador no lado do cliente fazer primeiro install sem suporte direto. O documento SHALL incluir, no mínimo:

1. Como criar um fine-grained PAT no GitHub (passos UI), com scope `read:packages` apenas E expiração 90 dias.
2. Comando exato de `helm registry login ghcr.io` (substituindo placeholder do username e PAT).
3. Comandos de install para cada chart disponível, com placeholders para values.
4. Procedimento de rotação manual: como gerar novo PAT antes do anterior expirar e fazer `helm registry logout` + novo `login`.

#### Scenario: Documento existe e está completo

- **WHEN** alguém abre `docs/onboarding-cliente.md`
- **THEN** o documento contém seções para: criação de PAT, login, install (chart-base e zabbix-proxy), rotação
- **AND** todos os comandos têm placeholders explicitamente marcados (ex: `<seu-bot-username>`, `<seu-PAT>`)

#### Scenario: Cliente segue documento e instala com sucesso

- **WHEN** um operador novo segue `docs/onboarding-cliente.md` linha-a-linha em uma máquina nova
- **THEN** após executar todos os passos, consegue rodar `helm install` em um chart deste repo
- **AND** não precisa de informação adicional fora do documento (exceto credenciais entregues separadamente: bot username e PAT)

### Requirement: README raiz documenta install OCI

O `README.md` na raiz do repositório SHALL conter uma seção "Instalação" que:

1. Avisa que packages são privados (PAT necessário).
2. Mostra fluxo `helm registry login` + `helm install oci://...`.
3. Linka para `docs/onboarding-cliente.md` para detalhes de provisionamento de cliente.

A seção SHALL substituir qualquer instrução anterior baseada em path local (`./charts/<chart>`) ou GitHub Pages.

#### Scenario: README atualizado

- **WHEN** o `README.md` é renderizado
- **THEN** contém uma seção "Instalação" com:
  - Aviso sobre packages privados
  - Bloco de comando com `helm registry login ghcr.io`
  - Bloco de comando com `helm install oci://ghcr.io/rst-services/charts/<chart> --version <version>`
  - Link para `docs/onboarding-cliente.md`
- **AND** não menciona `helm repo add` para GitHub Pages (não é o método autorizado)
