> **Nota**: Esta change foi criada retroativamente para formalizar trabalho já implementado antes da adoção do OpenSpec. Todas as tasks estão marcadas como concluídas (`[x]`) — o objetivo é estabelecer a baseline a partir da qual changes futuras farão deltas.

## 1. Estrutura do repositório

- [x] 1.1 Criar layout: `charts/`, `examples/`, raiz com `README.md`
- [x] 1.2 Configurar `.helmignore` em cada chart

## 2. chart-base 0.2.0

- [x] 2.1 Criar `Chart.yaml` (`apiVersion: v2`, `type: application`, `version: 0.2.0`, `kubeVersion: ">=1.24.0-0"`)
- [x] 2.2 Definir `values.yaml` com seções: `kind` toggle, `image` (com `digest`), `imagePullSecrets`, `command`/`args`, `env`/`envFrom`, `container.ports`, `service` (com `headless`), `resources`, probes (`readiness`/`liveness`/`startup`), `podSecurityContext`, `securityContext`, scheduling (`nodeSelector`/`tolerations`/`affinity`/`topologySpreadConstraints`/`priorityClassName`), `podAnnotations`/`podLabels`, `serviceAccount`, `initContainers`, `extraVolumes`/`extraVolumeMounts`, `configmap`/`secret`, `persistentVolume`, `statefulSet.volumeClaimTemplates`, `virtualService` + `letsEncrypt`
- [x] 2.3 Implementar `templates/_helpers.tpl` com `name`, `fullname`, `chart`, `labels` (incluindo k8s recomendados), `selectorLabels` (apenas `name`+`instance`), `serviceAccountName`, `statefulSetServiceName`, `gateway.uniqueHosts`
- [x] 2.4 Implementar `templates/workload.yaml` unificado renderizando Deployment OU StatefulSet conforme `.Values.kind`, suportando `volumeClaimTemplates` quando StatefulSet
- [x] 2.5 Implementar `templates/service.yaml` com toggle `headless` (clusterIP None)
- [x] 2.6 Implementar `templates/serviceaccount.yaml` (condicional em `serviceAccount.create`)
- [x] 2.7 Implementar `templates/configmap.yaml` e `templates/secret.yaml` (Secret usando `stringData`)
- [x] 2.8 Implementar `templates/pvc.yaml` (apenas para `kind: Deployment` + `persistentVolume.enabled`)
- [x] 2.9 Implementar `templates/virtualservice.yaml`, `gateway.yaml`, `certificate.yaml` (Istio + cert-manager opcionais)
- [x] 2.10 Escrever `charts/chart-base/CHANGELOG.md` documentando 0.2.0 e mudanças breaking vs versão interna 0.1.4

## 3. zabbix-proxy 0.1.0

- [x] 3.1 Criar `Chart.yaml` (`type: application`, `version: 0.1.0`, `appVersion: "7.0.16"`, `kubeVersion: ">=1.24.0-0"`)
- [x] 3.2 Definir `values.yaml` com API flat: `serverHost`, `hostname`, `mode`, `serverPort`, `psk.{enabled,identity,value,existingSecret}`, `proxyBufferMode`, `timeout`, `debugLevel`, `image`, `imagePullSecrets`, `persistence.{size,storageClass,accessMode}`, `replicas`, `resources`, scheduling, `podAnnotations`/`podLabels`, `service`, `serviceAccount`, `extraEnv`/`extraVolumes`/`extraVolumeMounts`
- [x] 3.3 Implementar `templates/_helpers.tpl` com helpers padrão + `pskSecretName`
- [x] 3.4 Implementar `templates/statefulset.yaml`: validações `required` (serverHost) e `fail` (PSK identity + value/existingSecret), env Zabbix, security defaults non-root (UID 1997, drop ALL caps), `volumeClaimTemplates` para SQLite buffer, mounts condicionais para PSK e extraVolumes
- [x] 3.5 Implementar `templates/service.yaml` (ClusterIP porta 10051, target `zbx-proxy`)
- [x] 3.6 Implementar `templates/secret-psk.yaml` (condicional em `psk.enabled` AND `psk.value` AND NOT `psk.existingSecret`)
- [x] 3.7 Implementar `templates/serviceaccount.yaml` (condicional em `serviceAccount.create`)
- [x] 3.8 Implementar `templates/NOTES.txt` com instruções pós-install (cadastro no Zabbix Server, modo, hostname, kubectl logs)
- [x] 3.9 Escrever `charts/zabbix-proxy/CHANGELOG.md` documentando 0.1.0

## 4. Exemplos

- [x] 4.1 Criar `examples/chart-base-deployment.yaml` (app stateless de cliente, com env, probes, securityContext)
- [x] 4.2 Criar `examples/chart-base-statefulset.yaml` (Redis-like, com volumeClaimTemplates)
- [x] 4.3 Criar `examples/zabbix-proxy-active.yaml` (configuração mínima por cliente)
- [x] 4.4 Criar `examples/zabbix-proxy-psk.yaml` (com TLS PSK opcional)

## 5. Documentação raiz

- [x] 5.1 `README.md` com tabela de charts, instruções de instalação local, links para examples, tabela de migração `helm-zabbix-proxy → zabbix-proxy`, convenções, política de versionamento

## 6. OpenSpec

- [x] 6.1 Inicializar OpenSpec (`openspec/`)
- [x] 6.2 Preencher `openspec/config.yaml` com contexto do projeto e rules per-artifact
- [x] 6.3 Criar esta change `initial-charts-baseline` com proposal, design, specs (3 capabilities) e tasks

## 7. Validação

- [x] 7.1 `helm lint charts/chart-base` passa sem erros
- [x] 7.2 `helm lint charts/zabbix-proxy --set serverHost=x` passa sem erros
- [x] 7.3 `helm template` renderiza sem erro: `chart-base` default, `chart-base` com `examples/chart-base-deployment.yaml`, `chart-base` com `examples/chart-base-statefulset.yaml`
- [x] 7.4 `helm template` renderiza sem erro: `zabbix-proxy` com `examples/zabbix-proxy-active.yaml`, `zabbix-proxy` com `examples/zabbix-proxy-psk.yaml --set psk.value=...`, `zabbix-proxy --set mode=passive`
- [x] 7.5 `helm template zabbix-proxy` SEM `serverHost` falha com mensagem `serverHost is required` (validação `required`)
- [x] 7.6 `helm template zabbix-proxy --set psk.enabled=true` (sem identity ou value) falha com mensagem clara (validação `fail`)
- [x] 7.7 Verificar manualmente que todo recurso renderizado contém os 5 labels k8s recomendados em `metadata.labels`
- [x] 7.8 Verificar que selector `matchLabels` em todos os workloads tem APENAS `app.kubernetes.io/name` e `app.kubernetes.io/instance`
