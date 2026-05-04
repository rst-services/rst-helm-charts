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

- [x] 5.1 Criar `docs/onboarding-cliente.md` com seção "1. Criar PAT no GitHub": instruções UI (Settings → Developer settings → Personal access tokens → Fine-grained tokens), scope `read:packages`, expiração 90 dias, repo access `Selected repositories: rst-services/rst-helm-charts` *(seção descreve o processo no contexto Padrão 2: PAT é gerado pelo admin, não pelo cliente)*
- [x] 5.2 Seção "2. Login no registry OCI": comando `echo $PAT | helm registry login ghcr.io -u <bot-username> --password-stdin` com placeholders explícitos
- [x] 5.3 Seção "3. Primeiro install": exemplos para `chart-base` e `zabbix-proxy` com placeholders e `-f my-values.yaml`
- [x] 5.4 Seção "4. Rotação de PAT": gerar novo PAT antes da expiração, `helm registry logout ghcr.io`, novo `helm registry login`, validar com `helm pull` de teste
- [x] 5.5 Seção "5. Troubleshooting comum": "auth required" → expirado/sem scope correto; "manifest unknown" → versão errada; "denied" → bot user sem acesso ao package
- [x] 5.6 Adicionar nota no topo: "Documento entregue ao cliente junto com bot username e PAT por canal seguro"

## 6. Validação local (antes do primeiro release)

- [x] 6.1 Validar sintaxe YAML dos workflows com `actionlint` localmente (ou via container `rhysd/actionlint`)
- [x] 6.2 Simular extração de release notes localmente: rodar o awk/sed snippet sobre `charts/chart-base/CHANGELOG.md` e validar saída
- [x] 6.3 Simular `helm package` localmente: `helm package charts/chart-base` e inspecionar `chart-base-0.2.0.tgz`
- [ ] 6.4 Verificar que `helm push` funciona via teste manual em uma tag de "dry-run" prévia (ex: `chart-base-0.2.0-rc1`) — apagar package após teste *(deferido para o grupo 7 — requer repo no GitHub criado e tag pushada)*
- [ ] 6.5 Confirmar visibilidade default do package após primeiro push (private esperado); ajustar se necessário via UI *(deferido para o grupo 7)*

## 7. Primeiro release oficial

- [ ] 7.1 Garantir que `charts/chart-base/CHANGELOG.md` tem seção `## 0.2.0` completa (já está — verificar)
- [ ] 7.2 Garantir que `charts/zabbix-proxy/CHANGELOG.md` tem seção `## 0.1.0` completa (já está — verificar)
- [ ] 7.3 Push da tag `chart-base-0.2.0` em `main`; aguardar workflow completar; verificar package em `github.com/orgs/rst-services/packages` E GitHub Release criada
- [ ] 7.4 Push da tag `zabbix-proxy-0.1.0`; mesma verificação
- [ ] 7.5 Smoke test em cluster pessoal: `helm registry login` + `helm install oci://...` para cada chart, confirmando install end-to-end
- [ ] 7.6 Atualizar `README.md` raiz para refletir que os primeiros releases foram publicados (substitui "Ainda não publicado" se ainda houver)

## 8. Documentação da change

- [x] 8.1 Atualizar `charts/chart-base/CHANGELOG.md` se algum ajuste em 0.2.0 for necessário (ex: nota de "primeira release publicada via GitHub") — adicionada nota de distribuição OCI no topo da seção 0.2.0
- [x] 8.2 Atualizar `charts/zabbix-proxy/CHANGELOG.md` similarmente se aplicável — adicionada nota de distribuição OCI no topo da seção 0.1.0
- [ ] 8.3 Após primeiro release bem-sucedido, executar `openspec archive publish-via-github-actions` para promover specs e arquivar *(deferido — depende do grupo 7)*
