## Context

O chart `zabbix-proxy` passou por um refactor pra "plumbing-only" (commit `a725818`): toda configuração do Zabbix migrou de campos first-class (`serverHost`, `mode`, `psk.enabled`, `proxyBufferMode`, ...) pra `extraEnv` puro com naming nativo do image (`ZBX_HOSTNAME`, `ZBX_SERVER_HOST`, `ZBX_PROXYMODE`, ...). Esse refactor, no entanto, manteve o `Chart.yaml` em `version: 0.1.0` — mesma versão que já havia sido publicada em `oci://ghcr.io/rst-services/charts/zabbix-proxy:0.1.0` com o schema antigo. Cliente que sincroniza ArgoCD apontando pra `targetRevision: 0.1.0` recebe o template antigo do GHCR e bate em `serverHost is required` ao usar values no novo formato.

Em paralelo, ao testar com `extraEnv: [{name: ZBX_PROXYBUFFERMODE, value: hybrid}]`, o pod sobe e morre imediatamente com `ProxyMemoryBufferSize configuration parameter must be set when ProxyBufferMode parameter is set to "memory" or "hybrid"` — regra do binário do Zabbix que não está documentada nos values nem no example.

O spec `openspec/specs/zabbix-proxy-deployment/spec.md` também ficou congelado no contrato pré-refactor: descreve `serverHost`, `mode`, `psk.enabled`, `proxyBufferMode` como first-class e como invariantes do chart. Está mentindo sobre a realidade.

## Goals / Non-Goals

**Goals:**
- Republicar o chart com versão limpa (`0.2.0`) cujo conteúdo no GHCR coincida com o conteúdo no repo.
- Documentar a regra `PROXYBUFFERMODE in (memory, hybrid) ⇒ PROXYMEMORYBUFFERSIZE` em dois lugares: `values.yaml` (comentário no `extraEnv`) e `examples/zabbix-proxy-active.yaml` (valor já no exemplo).
- Realinhar o spec `zabbix-proxy-deployment` ao contrato real do chart (plumbing-only, `extraEnv`-based).
- Registrar no `CHANGELOG.md` da chart o que mudou e por que (incluindo a divergência de schema do `0.1.0` publicado).

**Non-Goals:**
- Não introduzir `values.schema.json` neste change. Validação estrutural fica para um change separado.
- Não criar campos first-class novos (`proxyMemoryBufferSize` etc). A diretriz "extraEnv puro com naming nativo" continua valendo — a regra é apenas documentada.
- Não auto-injetar defaults quando o chart vê `hybrid`/`memory` no `extraEnv`. O chart continua sem inspecionar o conteúdo do `extraEnv`.
- Não deletar a tag `0.1.0` do GHCR como parte deste change. Pode ser feito depois manualmente; a partir de `0.2.0` a imutabilidade do registry passa a valer.
- Não tocar no chart `chart-base` nem no workflow de release.

## Decisions

### D1. Bump 0.1.0 → 0.2.0 (não 0.1.1)

**Decisão**: bumpar minor, não patch.

**Por quê**: o conteúdo de `0.1.0` no GHCR é incompatível com values no formato pós-refactor — quem migrou values pro `extraEnv` quebra ao puxar `0.1.0` do GHCR. Isso é breaking pra qualquer cliente que tenha tentado seguir o values.yaml atual. Em SemVer pré-1.0 a convenção é tolerar breaking em minor. `0.1.1` daria sinal errado de "compatível".

**Alternativa rejeitada**: republicar `0.1.0` com o conteúdo novo (force overwrite no registry). Quebra imutabilidade da tag, qualquer cache/Argo que já tenha sincronizado vê o conteúdo mudar debaixo dos pés.

### D2. `ZBX_PROXYMEMORYBUFFERSIZE` como documentação, não como first-class

**Decisão**: a regra é documentada em comentário no `values.yaml` e demonstrada no `examples/zabbix-proxy-active.yaml`. O chart não tem nenhum campo novo, nem inspeciona o conteúdo do `extraEnv` pra injetar defaults.

**Por quê**: a diretriz registrada do chart é "extraEnv puro, naming nativo, sem aliases nem first-class". Auto-injetar `ZBX_PROXYMEMORYBUFFERSIZE` ao detectar `ZBX_PROXYBUFFERMODE=hybrid` violaria isso — o chart passaria a "saber sobre Zabbix" novamente. Documentação resolve o caso comum (cliente lê o exemplo) sem custo arquitetural.

**Alternativa rejeitada**: campo `proxyBufferMode` + `proxyMemoryBufferSize` first-class com validação `fail` cruzada. Recriaria o problema que o refactor pra plumbing-only resolveu.

**Alternativa adiada**: `values.schema.json` com regra condicional (`if PROXYBUFFERMODE in (memory,hybrid) then require PROXYMEMORYBUFFERSIZE`). Boa ideia, mas o usuário explicitou que schema fica fora deste ciclo.

### D3. Realinhar spec `zabbix-proxy-deployment` neste mesmo change

**Decisão**: o spec é reescrito (delta `MODIFIED` cobrindo todos os requirements + `REMOVED` dos que não fazem mais sentido) pra refletir o chart pós-refactor.

**Por quê**: o spec está mentindo agora — descreve campos que não existem mais. Deixar pra "depois" mantém a mentira viva e dá margem a outro PR misturar regressão com refactor sem ninguém perceber. Como o bump 0.2.0 já é breaking, é o momento natural pra alinhar o contrato declarado.

**Alternativa rejeitada**: change separado só pra atualizar spec. Aumenta overhead sem ganho — o conteúdo do spec é determinado pelo refactor que motivou este bump.

### D4. Tom do CHANGELOG: honesto sobre a divergência

**Decisão**: o entry `0.2.0` cita explicitamente que o `0.1.0` publicado no GHCR foi gerado com schema pré-refactor e não corresponde ao `0.1.0` do repositório, e que `0.2.0` é o contrato definitivo.

**Por quê**: o cliente que viu o erro `serverHost is required` precisa entender por que a documentação do chart no repo discordava do que estava instalado. Sem essa explicação, fica suspeitando bug futuro. Honestidade aqui custa pouco e remove ruído de longo prazo.

## Risks / Trade-offs

- **[Risco]** Cliente que ainda aponta pra `0.1.0` continua quebrado até trocar `targetRevision` pra `0.2.0`. → **Mitigação**: comunicar o bump no CHANGELOG e via canal direto (cliente atual já está em contato — basta enviar o snippet de migração).
- **[Risco]** Outros clientes silenciosos (que não reportaram problema) podem estar usando o `0.1.0` antigo do GHCR e quebrar ao migrar. → **Mitigação**: o CHANGELOG `0.2.0` enumera as mudanças de schema, e o `extraEnv` é o único caminho — não há ambiguidade.
- **[Risco]** Sem schema, cliente continua podendo passar chaves desconhecidas (`serverHost: "..."`) e Helm aceita silenciosamente. → **Aceito por ora** — adicionar `values.schema.json` é o próximo ciclo.
- **[Risco]** Documentação da regra `PROXYBUFFERMODE/PROXYMEMORYBUFFERSIZE` depende do cliente ler comentário/example. Se ele copiar values minimalistas e setar só `hybrid`, o pod sobe e morre. → **Aceito por ora** — schema condicional resolveria; sem schema, a documentação é o melhor disponível.

## Migration Plan

Para cliente que está em `0.1.0`:

1. No `Application`/`ApplicationSet`, atualizar `targetRevision: 0.1.0 → 0.2.0`.
2. Substituir qualquer values com chaves first-class antigas (`serverHost`, `mode`, `psk`, `proxyBufferMode`, `timeout`, `debugLevel`, `serverPort`, `hostname`) por `extraEnv` com naming nativo. Tabela de tradução:

   | Old (0.1.0 antigo) | Novo (`extraEnv`) |
   |---|---|
   | `serverHost: x` | `- name: ZBX_SERVER_HOST` / `value: "x"` |
   | `hostname: ""` | `- name: ZBX_HOSTNAME` / `valueFrom.fieldRef.fieldPath: metadata.name` |
   | `mode: active`/`passive` | `- name: ZBX_PROXYMODE` / `value: "0"`/`"1"` |
   | `proxyBufferMode: hybrid` | `- name: ZBX_PROXYBUFFERMODE` / `value: "hybrid"` |
   | `timeout: 30` | `- name: ZBX_TIMEOUT` / `value: "30"` |
   | `debugLevel: 3` | `- name: ZBX_DEBUGLEVEL` / `value: "3"` |
   | `serverPort: 10051` | `- name: ZBX_SERVER_PORT` / `value: "10051"` |
   | `psk.enabled: true` + `psk.value`/`psk.identity` | `extraVolumes` montando Secret PSK + `ZBX_TLSCONNECT`/`ZBX_TLSPSKIDENTITY`/`ZBX_TLSPSKFILE` em `extraEnv` (ver `examples/zabbix-proxy-psk.yaml`) |

3. Se `ZBX_PROXYBUFFERMODE` estiver em `memory` ou `hybrid`, adicionar `ZBX_PROXYMEMORYBUFFERSIZE` (ex: `"256M"`).

**Rollback**: se `0.2.0` apresentar problema, cliente pode pinar em `0.1.0` (puxa o chart antigo do GHCR) — porém precisa reverter os values pro schema antigo. Para uma janela curta, é viável.

## Open Questions

- **Deletar tag `0.1.0` do GHCR depois de `0.2.0` publicada?** Não decidido neste change — fica como follow-up manual. A favor: evita cliente novo pegar lixo. Contra: quebra rollback. Provavelmente vale deletar depois de confirmação que ninguém-em-prod-importante está em `0.1.0`.
- **`values.schema.json` no próximo ciclo**: ambição mínima (bloquear chaves desconhecidas no chart) ou ambição maior (validar combinações de `ZBX_*` no `extraEnv`)? Decidido em change futuro.
