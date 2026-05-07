## Why

O chart `zabbix-proxy` foi refatorado para "plumbing-only" (StatefulSet + Service + PVC opcional, com toda config via `extraEnv`), mas a versão `0.1.0` publicada em `oci://ghcr.io/rst-services/charts/zabbix-proxy` foi gerada **antes** desse refactor — ela ainda exigia campos first-class (`serverHost`, `mode`, `psk.enabled`, etc) que não existem mais no chart do repositório. Cliente que instala `0.1.0` direto do GHCR recebe o template antigo e bate em `serverHost is required`, e o spec `zabbix-proxy-deployment` em `openspec/specs/` também descreve o contrato antigo, divergindo da realidade atual do chart.

Além disso, faltou documentar uma regra do binário do Zabbix: quando `ZBX_PROXYBUFFERMODE` é `memory` ou `hybrid`, `ZBX_PROXYMEMORYBUFFERSIZE` é obrigatório — sem isso o pod sobe e morre com `ProxyMemoryBufferSize configuration parameter must be set`.

## What Changes

- **BREAKING** — bump `charts/zabbix-proxy/Chart.yaml` `version: 0.1.0 → 0.2.0`. Justifica-se por SemVer pré-1.0: o `0.2.0` republica o chart com o contrato definitivo (plumbing-only via `extraEnv`), substituindo o `0.1.0` que foi publicado no GHCR com schema divergente do repositório pós-refactor.
- Documentar no `charts/zabbix-proxy/values.yaml` (em comentário no exemplo do `extraEnv`) a regra `ZBX_PROXYBUFFERMODE in (memory, hybrid) ⇒ ZBX_PROXYMEMORYBUFFERSIZE obrigatório`.
- Atualizar `examples/zabbix-proxy-active.yaml` adicionando `ZBX_PROXYMEMORYBUFFERSIZE` ao lado do `ZBX_PROXYBUFFERMODE: hybrid` que já está lá, com comentário inline explicando a regra.
- Atualizar `charts/zabbix-proxy/CHANGELOG.md` com entry `0.2.0` que (a) lista as mudanças e (b) explica que `0.1.0` no GHCR divergiu do repo pós-refactor — `0.2.0` é o contrato definitivo.
- **Atualizar spec `zabbix-proxy-deployment`** pra refletir o chart real (plumbing-only, `extraEnv`-based) — o conteúdo atual descreve o chart pré-refactor e está desalinhado do que está em `charts/zabbix-proxy/`.

## Não-objetivos

- **Sem `values.schema.json`** nesta versão. A validação estrutural de values fica para um ciclo futuro.
- **Sem first-class field para `proxyMemoryBufferSize`** (ou qualquer ZBX_*). A diretriz "extraEnv puro" continua valendo — a regra é apenas documentada.
- **Sem auto-injeção de defaults** quando o chart vê `hybrid`/`memory` no `extraEnv`. Cliente continua responsável por declarar o env explicitamente.
- **Sem deletar a tag `0.1.0` do GHCR** neste change. Pode ser feito depois manualmente; a imutabilidade já fica restabelecida a partir de `0.2.0`.

## Capabilities

### New Capabilities

(nenhuma)

### Modified Capabilities

- `zabbix-proxy-deployment`: realinhar todo o spec ao contrato atual do chart (plumbing-only, `extraEnv`-based). Remover requirements que descrevem campos first-class inexistentes (`serverHost`, `mode`, `psk.enabled`, `proxyBufferMode`, `timeout`, `debugLevel`, `serverPort`, `hostname`); adicionar requirement que documenta a regra `ZBX_PROXYBUFFERMODE in (memory, hybrid) ⇒ ZBX_PROXYMEMORYBUFFERSIZE` como contrato documental (não enforced via template).

## Impact

- **Tipo de mudança**: breaking compatível com pré-1.0 (bump minor).
- **Charts afetados**: `charts/zabbix-proxy/` (Chart.yaml, values.yaml, CHANGELOG.md).
- **Examples afetados**: `examples/zabbix-proxy-active.yaml`.
- **Specs afetados**: `openspec/specs/zabbix-proxy-deployment/spec.md` (rewrite parcial).
- **Cliente final**: precisa trocar `targetRevision: 0.1.0 → 0.2.0` no Application/ApplicationSet; precisa migrar values pra usar exclusivamente `extraEnv` (já era a expectativa após o refactor); precisa adicionar `ZBX_PROXYMEMORYBUFFERSIZE` se usar buffer mode `hybrid`/`memory`.
- **Pipeline release**: o workflow de publish já existente (capability `release-automation`) republica o package OCI quando uma tag `zabbix-proxy-0.2.0` for criada. Sem mudança no pipeline.
