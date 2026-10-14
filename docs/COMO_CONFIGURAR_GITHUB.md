# GitHub Actions — CI/CD do Voa Águia

Referências: [README](../README.md), [PDF técnico](Voa_Aguia_Relatorio_Tecnico_DevOps_Final.pdf), página 5 (fluxo), páginas 7–9 (jobs) e página 11 (ocorrências). A implementação está em [ci-cd.yml](../.github/workflows/ci-cd.yml) e [render-deploy.sh](../scripts/render-deploy.sh).

## 1. Eventos, branches e environments

| Evento | Validação CI | Destino CD |
|---|---|---|
| Pull request com destino `develop` ou `main` | `build-test` | Nenhum |
| Push em `develop` | `build-test` | `staging` |
| Push em `main` | `build-test` | `production` |
| `workflow_dispatch` em `develop` | `build-test` | `staging` |
| `workflow_dispatch` em `main` | `build-test` | `production` |
| `workflow_dispatch` em outra branch | `build-test` | Nenhum |

`develop` corresponde à homologação; `main`, à produção acadêmica. O fluxo de trabalho consiste em validar staging e promover por PR para `main`. O YAML não exige aprovação prévia em staging: ambos os jobs de deploy têm `needs: build-test`, e um push direto em `main` também seleciona produção.

Os environments GitHub `staging` e `production` identificam o destino e fornecem suas variáveis. Regras de aprovação, proteção de branches e checks obrigatórios são configuração externa; não estão comprovadas nas capturas. Consulte [environments do Actions](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments).

## 2. Preparar Render e Atlas

Configure dois Web Services Docker no Render, ligados ao repositório e às branches correspondentes, com `/healthz`, `MONGODB_URI` e `JWT_SECRET` próprios. O PDF identifica os bancos `voaaguia_staging` e `voaaguia_production` no mesmo cluster Atlas. Para centralizar o CD no workflow, configure Auto-Deploy `Off`; a chamada API com `commitId` não desliga auto-deploys automaticamente.

Consulte o [Guia Render e Atlas](GUIA_RENDER_ATLAS.md). O MongoDB usado pelo CI é temporário e não utiliza as credenciais Atlas. O runner executa validação; a API publicada fica no Render.

## 3. Cadastrar o repository secret

Em **Settings > Secrets and variables > Actions > Secrets > New repository secret**, cadastre:

| Nome | Tipo e escopo | Conteúdo |
|---|---|---|
| `RENDER_API_KEY` | Repository secret | Chave de API Render autorizada a acessar os dois serviços |

Esse escopo segue a solução relatada no PDF, página 11. O workflow referencia `${{ secrets.RENDER_API_KEY }}` e o disponibiliza ao processo como variável de ambiente. Não inclua a chave em YAML, Markdown, prints ou variáveis públicas. Veja [secrets do GitHub Actions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets).

O GitHub também permite environment secrets. Um `RENDER_API_KEY` cadastrado no environment tem precedência sobre o repository secret no job correspondente; revise eventual valor antigo nesse escopo se a autenticação falhar. Não é necessário duplicar o repository secret nos dois environments. Consulte a [referência de precedência de secrets](https://docs.github.com/en/actions/reference/security/secrets).

## 4. Configurar as variables dos environments

Em **Settings > Environments**, crie `staging` e `production`. Em cada um, adicione:

| Variable | `staging` | `production` |
|---|---|---|
| `RENDER_SERVICE_ID` | ID `srv-...` do serviço `esg-devops-staging` | ID `srv-...` do serviço `esg-devops-production` |
| `RENDER_PUBLIC_URL` | `https://esg-devops-staging.onrender.com` | `https://esg-devops-production.onrender.com` |

O YAML usa `${{ vars.RENDER_SERVICE_ID }}` e `${{ vars.RENDER_PUBLIC_URL }}`. Cadastre-os como **Variables**, não somente como Secrets. A URL é a base HTTPS, sem `/swagger-ui/index.html` ou `/healthz`. O ID real vem do painel Render e não precisa ser transcrito para a documentação.

`MONGODB_URI`, `JWT_SECRET` e demais configurações da aplicação ficam no Render. `GITHUB_SHA` é fornecida automaticamente pelo Actions.

## 5. Etapas de CI implementadas

O job **Compilar, testar e construir imagem Docker** (`build-test`) executa em `ubuntu-latest`:

1. `actions/checkout@v4` obtém o código.
2. O serviço `mongo:7.0` disponibiliza porta 27017 e healthcheck `mongosh` com `ping`, intervalo/timeout de 5s e 20 tentativas.
3. `actions/setup-java@v4` prepara Temurin 17 e cache Maven.
4. `bash ./mvnw --batch-mode --no-transfer-progress clean verify` compila, executa testes e empacota o backend.
5. `docker build --tag voaaguia:${{ github.sha }} .` valida a construção da imagem.
6. `actions/upload-artifact@v4`, com `if: always()`, envia `target/surefire-reports/` como `testes-<run_number>` quando houver arquivos. `if-no-files-found: ignore` não torna ausência de relatórios uma falha.

A suíte usa banco aleatório de testes, separado do banco local e do Atlas, e remove esse banco ao final. O teste de auditoria usa H2. A imagem construída no CI não é enviada para registry; o Render reconstrói a imagem a partir do Dockerfile e do commit solicitado.

## 6. Etapas de CD implementadas

Os jobs **Deploy Render - staging** e **Deploy Render - producao academica** dependem do CI da própria execução. Ambos usam checkout, environment correspondente, timeout de 35 minutos e `bash scripts/render-deploy.sh`.

O script:

1. Exige `RENDER_API_KEY`, `RENDER_SERVICE_ID`, `RENDER_PUBLIC_URL` e `GITHUB_SHA` não vazios.
2. Solicita `POST /v1/services/{serviceId}/deploys`, com `commitId=GITHUB_SHA` e autenticação Bearer. Aceita HTTP 201 ou 202.
3. Obtém o ID do deploy pela resposta JSON; ausência do ID interrompe a execução.
4. Aguarda 15 segundos e consulta o status; faz até 90 consultas, além do tempo das requisições.
5. Continua somente ao atingir `live`.
6. Consulta `<RENDER_PUBLIC_URL>/healthz` com retry, timeout de conexão de 15s e limite de 50s por transferência.
7. Usa `jq` para exigir `status == "UP"` e `application == "voaaguia"`, então imprime `Deploy LIVE + HTTP health check OK` com o SHA abreviado.

Cada ambiente usa um grupo `concurrency`: `render-voaaguia-staging` ou `render-voaaguia-production`, com `cancel-in-progress: false`. A publicação em execução não é cancelada pelo workflow quando chega outra execução do mesmo ambiente; a configuração limita concorrência, sem garantir que todos os commits intermediários sejam publicados. Veja [concorrência no Actions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency).

A API Render suporta a seleção por `commitId`; consulte [Trigger deploy](https://api-docs.render.com/reference/create-deploy). O SHA associa o deploy ao código validado. Os testes e a imagem construída no CI não são transferidos para a instância Render.

## 7. Critérios de sucesso e falha

| Etapa | Sucesso | Falha |
|---|---|---|
| Maven | `clean verify` encerra com código zero | Erro de compilação, teste ou empacotamento |
| Docker | Construção encerra com código zero | Falha no Dockerfile, dependências ou build |
| Solicitação Render | HTTP 201/202 e ID de deploy presente | Variável ausente, HTTP diferente ou JSON sem ID |
| Acompanhamento | Status `live` | `build_failed`, `update_failed`, `pre_deploy_failed`, `canceled`, `deactivated` ou limite de consultas |
| HTTP de saúde | Requisição e JSON passam na condição `jq` | Falha HTTP/transporte, JSON inválido ou campos divergentes |
| Job CD | Script termina com sucesso antes de 35 minutos | Erro de comando (`set -euo pipefail`) ou timeout do job |

`GET /healthz` é público e executa `ping` no MongoDB. Um Swagger carregado comprova a documentação acessível; o healthcheck acrescenta verificação da conexão de banco. O job de PR pode ser verde sem executar CD, pois os jobs de deploy são pulados.

## 8. Evidências e acompanhamento

No GitHub, abra **Actions > Voa Aguia - CI/CD (Render e Atlas)** e selecione a execução. O PDF registra o job de CI aprovado (p. 7), staging com `live`/healthcheck OK (p. 8) e produção com `live`/healthcheck OK (p. 9). Essas capturas estão incorporadas ao PDF.

O [PNG do histórico](evidencias/actionsSuccess.png) mostra as execuções `#5`–`#8` verdes. A contagem de testes não aparece nesses prints. Os relatórios locais da revisão anterior registram nove testes, mas não representam contagem comprovada da execução remota.

Para conferir uma nova execução, compare o SHA do Actions e do deploy no painel Render, consulte o artefato de testes e confira a mensagem final de saúde. Esta revisão documental não executa deploys, commits ou pushes. O [relatório de auditoria](REVISAO_DOCUMENTACAO.md) registra os limites da conferência.
