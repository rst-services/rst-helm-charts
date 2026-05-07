## 1. Setup do repositório

- [x] 1.1 Adicionar `LICENSE` na raiz com texto integral da Apache 2.0 (referência: https://www.apache.org/licenses/LICENSE-2.0.txt). Substituir `[yyyy]` por `2026` e `[name of copyright owner]` por `Robert Silva`
- [x] 1.2 Adicionar `.gitignore` na raiz cobrindo: `*.tgz`, `.DS_Store`, `Thumbs.db`, `.idea/`, `.vscode/`, `.helmignore.bak`, `*.swp`, `*.tmp`

## 2. Workflow de PR validation

- [x] 2.1 Criar `.github/workflows/pr-validation.yml` com triggers: `pull_request` em `main`, paths `charts/**` e `examples/**`
- [x] 2.2 Job `lint-and-template`: runner `ubuntu-latest`, declarar `permissions: { contents: read }`
- [x] 2.3 Step: checkout com `fetch-depth: 2` (necessário pra detectar diff)
- [x] 2.4 Step: setup helm via `azure/setup-helm@v4` (versão fixa, ex: 3.15.x)
- [x] 2.5 Step: detectar charts modificados usando `dorny/paths-filter@v3` (output: lista de charts alterados)
- [x] 2.6 Step: para cada chart modificado, rodar `helm lint charts/<chart>` e falhar se errar
- [x] 2.7 Step: para cada chart modificado, rodar `helm template t charts/<chart> -f examples/<chart>-*.yaml` (com `--set` mínimo pra contornar `required` se necessário, ex: `serverHost=ci-test`)
- [x] 2.8 Adicionar concurrency group pra cancelar runs antigos quando push novo no mesmo PR

## 3. Workflow de release

- [x] 3.1 Criar `.github/workflows/release.yml` com trigger `push: tags: ['*-*']` (capturando formato `<chart>-<version>`)
- [x] 3.2 Declarar `permissions: { contents: write, packages: write }` no nível do job
- [x] 3.3 Step: checkout do código
- [x] 3.4 Step: extrair `chart_name` e `version` da tag via shell parsing (regex `^(.+)-([0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9.]+)?)$`)
- [x] 3.5 Step: validar que `charts/$chart_name/` existe; falhar se não
- [x] 3.6 Step: validar que `charts/$chart_name/Chart.yaml version` é igual a `$version` (yq); falhar se mismatch
- [x] 3.7 Step: setup helm
- [x] 3.8 Step: `helm package charts/$chart_name -d /tmp/`
- [x] 3.9 Step: `helm registry login ghcr.io -u ${{ github.actor }} --password-stdin <<< ${{ secrets.GITHUB_TOKEN }}`
- [x] 3.10 Step: `helm push /tmp/${chart_name}-${version}.tgz oci://ghcr.io/rst-services/charts`
- [x] 3.11 Step: extrair seção do `charts/$chart_name/CHANGELOG.md` correspondente à versão (awk/sed entre `## $version` e próxima `## ` ou EOF). Se vazio, usar texto padrão "Release notes pendentes"
- [x] 3.12 Step: criar GitHub Release usando `softprops/action-gh-release@v2` com tag, `body` da extração, e `files: /tmp/${chart_name}-${version}.tgz`

## 4. Atualização do README raiz

- [x] 4.1 Substituir seção "Instalação" no `README.md` raiz por instruções OCI (ver template no design.md / specs)
- [x] 4.2 Adicionar aviso destacado: "Packages são privados; precisa de PAT (ver `docs/onboarding-cliente.md`)"
- [x] 4.3 Adicionar bloco de comando `helm registry login ghcr.io` e `helm install oci://ghcr.io/rst-services/charts/<chart> --version <version>`
- [x] 4.4 Adicionar link explícito para `docs/onboarding-cliente.md`
- [x] 4.5 Atualizar tabela de charts pra remover qualquer menção a path local como método autorizado
- [x] 4.6 Atualizar seção "Publicação" removendo o "Ainda não publicado" e descrevendo o fluxo OCI ativo

## 5. Documento de onboarding de cliente

- [x] 5.1–5.6 Doc `docs/onboarding-cliente.md` foi criado durante a change, mas **deletado após decisão de mudar visibilidade dos packages para público** (2026-05-04). Sem PAT/auth, o doc virou repetição do README. Tasks originais (criação de PAT, login, rotação, troubleshooting de auth) ficaram obsoletas.

## 6. Validação local (antes do primeiro release)

- [x] 6.1 Validar sintaxe YAML dos workflows com `actionlint` localmente (ou via container `rhysd/actionlint`)
- [x] 6.2 Simular extração de release notes localmente: rodar o awk/sed snippet sobre `charts/chart-base/CHANGELOG.md` e validar saída
- [x] 6.3 Simular `helm package` localmente: `helm package charts/chart-base` e inspecionar `chart-base-0.2.0.tgz`
- [x] 6.4 `helm push` validado em produção via tag real (sem rc1 — direto pra release) em 2026-05-04
- [x] 6.5 Visibilidade do package: default era "private"; **flipada para "public"** após habilitar packages públicos na org `rst-services` (org settings → packages)

## 7. Primeiro release oficial

- [x] 7.1 `charts/chart-base/CHANGELOG.md` seção `## 0.2.0` verificada
- [x] 7.2 `charts/zabbix-proxy/CHANGELOG.md` seção `## 0.1.0` verificada
- [x] 7.3 Tag `chart-base-0.2.0` pushada em 2026-05-04; workflow `Release Chart` succeeded em 25s; package + GitHub Release criados
- [x] 7.4 Tag `zabbix-proxy-0.1.0` pushada em 2026-05-04; workflow succeeded em 24s; package + GitHub Release criados
- [x] 7.5 Smoke test: `helm pull oci://ghcr.io/rst-services/charts/chart-base --version 0.2.0` e `zabbix-proxy --version 0.1.0` anônimo (sem login) — ambos puxaram .tgz com sucesso
- [x] 7.6 `README.md` raiz atualizado: removido aviso "packages privados", install simplificado (sem `helm registry login`), link pro doc deletado removido

## 8. Documentação da change

- [x] 8.1 Atualizar `charts/chart-base/CHANGELOG.md` se algum ajuste em 0.2.0 for necessário (ex: nota de "primeira release publicada via GitHub") — adicionada nota de distribuição OCI no topo da seção 0.2.0
- [x] 8.2 Atualizar `charts/zabbix-proxy/CHANGELOG.md` similarmente se aplicável — adicionada nota de distribuição OCI no topo da seção 0.1.0
- [x] 8.3 Executar `openspec archive publish-via-github-actions` para promover specs e arquivar — passo final, agora desbloqueado
