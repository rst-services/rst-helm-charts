## Context

O repositório `rst-services/rst-helm-charts` é privado no GitHub. Decisões já tomadas:

- **Distribuição via OCI no `ghcr.io`** (não GitHub Pages, já que Pages requer repo público).
- **Packages privados** no `ghcr.io` — cada cliente autentica com PAT próprio antes de instalar (Padrão 2: machine user por cliente).
- **Apache 2.0** como licença, padronizada no Helm ecosystem.
- **Tag-driven releases** com convenção `<chart-name>-<version>` já estabelecida em `repository-conventions`.

A seguinte change `client-onboarding-pipeline` (em backlog) automatizará o provisionamento de novo cliente. Esta change foca apenas em release + documentação manual de install.

## Goals / Non-Goals

**Goals:**

- Pipeline de validação automática em PRs (impede merge com chart quebrado).
- Pipeline de release tag-driven, idempotente, com release notes do `CHANGELOG`.
- Distribuição OCI configurada em `ghcr.io/rst-services/charts/<chart>`.
- Documentação suficiente para um cliente novo conseguir instalar sem suporte direto, seguindo `docs/onboarding-cliente.md`.

**Non-Goals:**

- Automação de criação de bot users / PATs / kit de cliente (vira change `client-onboarding-pipeline`).
- Rotação automática de PAT.
- Testes de install em cluster real (`ct install` + `kind`) — fica pra change futura.
- Validação semântica de values (`values.schema.json`, `kubeconform`).
- Assinatura de charts (cosign / Sigstore).
- Publicação simultânea em GitHub Pages ou outro registry.
- Mudanças nos charts atuais (`chart-base`, `zabbix-proxy`).

## Decisions

### D1. OCI no `ghcr.io` em vez de GitHub Pages

**Decisão**: publicar charts como packages OCI em `oci://ghcr.io/rst-services/charts/<chart>`.

**Rationale**: GitHub Pages requer repo público OU plano Enterprise. Repo é privado, sem Enterprise. OCI no `ghcr.io` é gratuito, suporta packages privados nativamente, e Helm 3.8+ tem suporte OCI estável. Alternativas consideradas:

- **GitHub Pages com repo público**: rejeitado (decisão de manter source privado).
- **ChartMuseum / Harbor self-hosted**: overhead operacional desnecessário pra escala atual.
- **Apenas distribuir `.tgz` em GitHub Releases**: cliente teria que baixar manualmente; sem `helm repo` ou `oci://` flow nativo.

### D2. Tag-driven release: `<chart>-<version>` dispara workflow

**Decisão**: workflow de release dispara em push de tag matching `<chart-name>-<version>` (ex: `chart-base-0.2.0`). O prefixo identifica qual chart empacotar.

**Rationale**: convenção já estabelecida em `repository-conventions`. Permite releases independentes dos charts (cada um no seu ritmo). Alternativas:

- **Manual workflow_dispatch com input**: mais flexível mas suscetível a typos no nome do chart/versão.
- **Push em branch específica**: acopla release com merge, ruim para hotfix em versão antiga.
- **Tag única `vX.Y.Z`**: forçaria todos os charts a versionar juntos. Rejeitado por contradizer SemVer-por-chart.

### D3. Release notes do `CHANGELOG.md` do chart

**Decisão**: o workflow extrai a seção da versão sendo lançada do `charts/<chart>/CHANGELOG.md` e usa como corpo da GitHub Release.

**Rationale**: evita duplicação (release notes ≠ CHANGELOG seria fonte de divergência). Usuário só precisa atualizar `CHANGELOG.md` antes de fazer a tag.

**Implementação**: extrai a seção `## <version>` até a próxima `## ` (ou EOF) usando `awk`/`sed` no workflow.

**Risco**: se o `CHANGELOG.md` não tiver entrada para a versão da tag, release sai com notas vazias. Mitigation: workflow emite warning (não falha) e a entrada do CHANGELOG é uma das tasks de release humana, fácil de pegar antes.

### D4. PR validation: lint + template apenas

**Decisão**: workflow de PR roda `helm lint` em todos os charts modificados E `helm template` sobre cada example associado. NÃO roda `ct install` em `kind`.

**Rationale**: `ct install` adiciona ~3min por PR + complexidade (kind setup, recursos do runner) sem trazer cobertura proporcional pra charts simples como os atuais. `helm lint + template` cobre 90% dos erros (sintaxe, missing values, validation `required`/`fail`). Pode ser adicionado em change futura quando charts ficarem mais complexos.

**Detecção de charts modificados**: usa `dorny/paths-filter` ou equivalente pra detectar mudanças sob `charts/<X>/` e processar só esses.

### D5. Padrão de acesso de cliente: bot user por cliente (Padrão 2)

**Decisão**: cada cliente autenticado tem um bot user GitHub próprio (`rst-bot-clienteN`) com fine-grained PAT scope `read:packages`, expiração 90 dias.

**Rationale**: discutido em conversa de design.

- **Vs Padrão 1 (outside collaborator)**: cliente não precisa de conta GitHub própria; isolamento operacional total entre clientes.
- **Vs Padrão 3 (bot único + PATs múltiplos)**: bot único compromete TODOS os clientes se vazado; bot por cliente isola o blast radius.

**Trade-off**: credencial é compartilhada (você + cliente têm o PAT). Mitigado por: scope mínimo, expiração curta, rotação trimestral, e bot user com permissão só de `read:packages` (não consegue mexer em código nem outras orgs).

### D6. README na raiz vs README por chart

**Decisão**: README raiz cobre catálogo de charts e instruções gerais de install OCI. README individual por chart fica como melhoria futura (com `helm-docs`, gerado automaticamente).

**Rationale**: 1 fonte de verdade pra "como instalar qualquer chart deste repo" reduz divergência. Detalhes específicos de chart estão no `values.yaml` (bem-comentado) e `CHANGELOG.md`.

### D7. `docs/onboarding-cliente.md` separado do README

**Decisão**: documento separado em `docs/`, em vez de seção do README raiz.

**Rationale**: README é pra desenvolvedor que abre o repo. Onboarding de cliente é audiência diferente (operador no lado do cliente, não-desenvolvedor potencialmente). Separado, dá pra compartilhar só o link do `onboarding-cliente.md` no kit do cliente sem expor o resto do repo.

## Risks / Trade-offs

- **Risco**: `GITHUB_TOKEN` em workflows de PR de fork pode ter escopo restrito por GitHub (não consegue escrever packages). Mitigation: workflow de release roda em push de tag (não PR de fork), então não afeta. PR validation usa só read access, sem problema.

- **Risco**: tag pushada acidentalmente (typo, `git push --tags` em branch errada) dispara release fantasma. Mitigation: workflow valida formato `<chart-name>-<version>` no início; se chart não existe em `charts/`, falha cedo. Adicionalmente, podemos adicionar branch protection na main futuramente.

- **Risco**: `helm push` para registry OCI privado falha se o user não tem `packages: write`. Mitigation: workflow declara `permissions: { packages: write, contents: write }` explicitamente no YAML.

- **Trade-off**: SEM testes em cluster real (`kind`) — confiamos só em `helm lint`/`template`. Charts simples como os atuais sobrevivem; quando complexidade aumentar, adicionar `ct install` em change separada.

- **Trade-off**: cliente precisa de PAT manualmente. UX inicial menos amigável, mas decisão consciente de manter packages privados (controle de quem instala).

- **Risco**: primeiro release pode falhar por questões não previstas (escopo do token, formato esperado pelo `helm push`, etc.). Mitigation: na seção de tasks, fazemos primeiro release manualmente em modo dry-run / cluster pessoal pra validar antes de publicar oficialmente.

## Migration Plan

Esta change não migra usuários existentes — é greenfield (primeira publicação).

**Sequência após merge**:

1. Workflows entram em vigor automaticamente com o merge.
2. Tag `chart-base-0.2.0` é criada manualmente, dispara release.
3. Inspeção: package aparece em `github.com/orgs/rst-services/packages`, GitHub Release criada.
4. Mesmo pra `zabbix-proxy-0.1.0`.
5. Primeiro cliente real é onboarded seguindo `docs/onboarding-cliente.md`.

**Rollback**: se workflow de release tiver bug, deletar a tag (`git tag -d <name>; git push origin :<name>`) e o package no `ghcr.io` (via UI). Re-tagar após fix.

## Open Questions

- **Quem owns os GitHub Packages pós-publish**: precisamos verificar se `org admin` precisa explicitamente "claim" o package após primeiro push, ou se já fica anexado à org `rst-services`. Validar no primeiro release (item nas tasks).

- **Visibilidade default de novo package**: `ghcr.io` cria package como privado por default quando vem de org. Confirmar; senão, ajustar configuração do package após primeiro push (UI ou API).

- **Branch protection**: incluir nesta change ou separada? Sugerido: separada (tema "governance" mais amplo, fora do escopo de "publicação"). Anotado em backlog.

- **`helm-docs` para gerar README por chart**: backlog.
