## 1. Bump da versão

- [x] 1.1 Atualizar `charts/zabbix-proxy/Chart.yaml` `version: 0.1.0 → 0.2.0` (manter `appVersion: "7.0.16"`)
- [x] 1.2 Rodar `helm lint charts/zabbix-proxy` e validar `helm template t charts/zabbix-proxy -f examples/zabbix-proxy-active.yaml` e `examples/zabbix-proxy-psk.yaml` sem erros

## 2. Documentação da regra ProxyMemoryBufferSize

- [x] 2.1 Em `charts/zabbix-proxy/values.yaml`, na seção do `extraEnv`, adicionar comentário explicando que `ZBX_PROXYBUFFERMODE in (memory, hybrid)` exige `ZBX_PROXYMEMORYBUFFERSIZE` no mesmo `extraEnv`. Incluir exemplo comentado da chave.
- [x] 2.2 Em `examples/zabbix-proxy-active.yaml`, adicionar `- name: ZBX_PROXYMEMORYBUFFERSIZE` (ex: `value: "256M"`) ao lado do `ZBX_PROXYBUFFERMODE: hybrid` que já está lá. Comentário inline curto referenciando a regra.
- [x] 2.3 Re-rodar `helm template` no example active e confirmar que o env aparece no container.

## 3. CHANGELOG

- [x] 3.1 Em `charts/zabbix-proxy/CHANGELOG.md`, adicionar entry `## 0.2.0` (acima do `## 0.1.0`) com:
  - resumo das mudanças (documentação `ZBX_PROXYMEMORYBUFFERSIZE` no values e example)
  - nota explícita de que `0.1.0` publicado em `oci://ghcr.io/rst-services/charts/zabbix-proxy:0.1.0` foi gerado antes do refactor "plumbing-only" e não corresponde ao `0.1.0` do repositório — `0.2.0` é o contrato definitivo
  - tabela de migração resumida (do schema antigo first-class para `extraEnv`), referenciando `design.md` do change para detalhes
- [x] 3.2 Validar formato Keep-a-Changelog (linguagem pt-BR, consistente com entry 0.1.0 existente).

## 4. Validação fim-a-fim

- [x] 4.1 Rodar `helm lint charts/zabbix-proxy`.
- [x] 4.2 Rodar `helm template t charts/zabbix-proxy -f examples/zabbix-proxy-active.yaml` e conferir que o YAML rendered contém os envs `ZBX_PROXYBUFFERMODE`, `ZBX_PROXYMEMORYBUFFERSIZE`, `ZBX_HOSTNAME`, `ZBX_SERVER_HOST`.
- [x] 4.3 Rodar `helm template t charts/zabbix-proxy -f examples/zabbix-proxy-psk.yaml` e conferir que o YAML continua válido (regressão).
- [x] 4.4 Empacotar o chart localmente: `helm package charts/zabbix-proxy` na raiz do repo. Confirmar que gera `zabbix-proxy-0.2.0.tgz`. Remover o `zabbix-proxy-0.1.0.tgz` antigo do repo se ainda existir.

## 5. Pós-merge (release)

- [ ] 5.1 Após merge no `main`, criar tag git `zabbix-proxy-0.2.0` e push pra disparar workflow de publish (capability `release-automation`).
- [ ] 5.2 Confirmar que o package `oci://ghcr.io/rst-services/charts/zabbix-proxy:0.2.0` foi publicado e está public.
- [ ] 5.3 Comunicar ao cliente afetado o snippet de migração (trocar `targetRevision` no ApplicationSet + adicionar `ZBX_PROXYMEMORYBUFFERSIZE` no `extraEnv`).
