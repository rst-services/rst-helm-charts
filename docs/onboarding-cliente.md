# Onboarding de cliente — rst-helm-charts

> **Audiência**: operador no lado do cliente que vai instalar charts do `rst-services/rst-helm-charts` em um cluster Kubernetes.
>
> **Pré-requisitos**: você recebeu (por canal seguro do administrador `rst-services`) os seguintes itens:
>
> - **Bot username** GitHub (ex: `rst-bot-cliente1`)
> - **Personal Access Token (PAT)** desse bot user, com scope `read:packages` e expiração definida (90 dias por padrão)
> - Lista dos charts liberados para você (ex: `chart-base`, `zabbix-proxy`)

Se algum desses itens estiver faltando, contate o administrador antes de prosseguir.

---

## 1. Confirmar pré-requisitos no seu ambiente

Você precisa apenas de:

- **Helm 3.8+** (suporte OCI estável). Verifique:
  ```bash
  helm version --short
  # esperado: v3.8.x ou superior
  ```
- **Acesso ao cluster Kubernetes** onde o chart será instalado (`kubectl get nodes` deve funcionar).

Não é necessário ter conta GitHub própria nem clonar este repositório — você instala diretamente do registry OCI.

## 2. Login no registry OCI (`ghcr.io`)

Faça login uma vez por máquina (ou por sessão CI):

```bash
# Recomendado: PAT em variável de ambiente, sem ecoar em terminal
export GITHUB_PAT="<seu-PAT-aqui>"

echo "$GITHUB_PAT" | helm registry login ghcr.io \
  --username <seu-bot-username> \
  --password-stdin
```

Substitua:

- `<seu-PAT-aqui>` pelo PAT entregue
- `<seu-bot-username>` pelo username GitHub do bot user (ex: `rst-bot-cliente1`)

Saída esperada:

```
Login Succeeded
```

A credencial fica armazenada em `~/.config/helm/registry/config.json` (ou equivalente do seu OS) — sem precisar refazer login a cada install.

## 3. Primeiro install

### chart-base (genérico)

Para uma app stateless do seu cliente:

```bash
helm install minha-api oci://ghcr.io/rst-services/charts/chart-base \
  --version 0.2.0 \
  --namespace minha-app --create-namespace \
  -f values.yaml
```

Onde `values.yaml` é seu arquivo de configuração (use [`examples/chart-base-deployment.yaml`](../examples/chart-base-deployment.yaml) ou [`examples/chart-base-statefulset.yaml`](../examples/chart-base-statefulset.yaml) como referência).

### zabbix-proxy (Zabbix Proxy SQLite)

Configuração mínima por cliente — apenas `serverHost` é obrigatório:

```bash
helm install zbx-proxy oci://ghcr.io/rst-services/charts/zabbix-proxy \
  --version 0.1.0 \
  --namespace zabbix --create-namespace \
  --set serverHost=zabbix.empresa.com.br \
  --set hostname=PROXY-CLIENTE1
```

Para cenários mais elaborados (modo passive, TLS PSK, snippets de configuração), veja [`examples/zabbix-proxy-active.yaml`](../examples/zabbix-proxy-active.yaml) e [`examples/zabbix-proxy-psk.yaml`](../examples/zabbix-proxy-psk.yaml).

Após o install, o chart imprime instruções pós-install (NOTES.txt) explicando como cadastrar o proxy no Zabbix Server.

## 4. Atualizações e upgrades

```bash
# Para uma versão nova do mesmo chart
helm upgrade zbx-proxy oci://ghcr.io/rst-services/charts/zabbix-proxy \
  --version 0.2.0 \
  -n zabbix \
  -f values.yaml --reuse-values
```

Sempre consulte o `CHANGELOG.md` do chart no GitHub Release antes de fazer upgrade — mudanças breaking estão documentadas lá.

## 5. Rotação de PAT

PATs expiram em 90 dias por padrão. Antes da expiração:

1. Solicite ao administrador `rst-services` a geração de **novo PAT** para o seu bot user (ele vai logar no bot user e gerar um novo fine-grained token, mesmos scopes).
2. Receba o novo PAT por canal seguro.
3. No seu ambiente, faça logout e login com o novo:
   ```bash
   helm registry logout ghcr.io
   echo "$NOVO_PAT" | helm registry login ghcr.io \
     --username <seu-bot-username> \
     --password-stdin
   ```
4. Valide com um `helm pull` de teste:
   ```bash
   helm pull oci://ghcr.io/rst-services/charts/chart-base --version 0.2.0
   # Sucesso: arquivo chart-base-0.2.0.tgz no diretório atual; pode deletar.
   ```

> ⚠️ **NÃO use** o PAT antigo após receber o novo. Idealmente, peça ao administrador para revogar o PAT antigo imediatamente.

## 6. Troubleshooting

### `Error: failed to authorize: failed to fetch oauth token: ... 401 Unauthorized`

- PAT expirou ou foi revogado → veja seção "Rotação de PAT" acima.
- PAT está com scope errado → confirme que tem `read:packages` (e que o bot user foi adicionado ao package no lado do administrador).
- Username errado no `--username` → confira o bot username exato.

### `Error: ... manifest unknown`

- Versão pedida (`--version 0.X.Y`) não existe no registry. Confira tags publicadas em https://github.com/rst-services/rst-helm-charts/releases.

### `Error: ... denied`

- Bot user não foi adicionado como leitor desse package específico. Contate o administrador para garantir o acesso ao chart pedido.

### `Error: chart "..." not found`

- Nome do chart está errado, ou cache local de helm está obsoleto. Tente:
  ```bash
  helm pull oci://ghcr.io/rst-services/charts/<chart-name> --version <version> --debug
  ```

## 7. Suporte

Para qualquer problema não coberto acima, contate o administrador `rst-services` com:

- Comando exato que falhou
- Output completo do helm com `--debug`
- Versão do helm (`helm version`) e do cluster (`kubectl version`)
