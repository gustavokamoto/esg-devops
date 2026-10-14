# Evidências de execução — Voa Águia

As cinco imagens em `docs/evidencias/` e as capturas incorporadas ao [PDF técnico](Voa_Aguia_Relatorio_Tecnico_DevOps_Final.pdf) registram execução local, CI, deploys e bancos Atlas. Os nomes originais foram preservados. Esta análise distingue o conteúdo visual, o relato do relatório e a implementação atual; a identidade acadêmica está no [README](../README.md).

## 1. Containers locais

Arquivo: [containerLocal.png](evidencias/containerLocal.png).

![Containers locais](evidencias/containerLocal.png)

O terminal mostra o comando `docker ps` e dois containers:

| Container | Imagem | Estado registrado | Porta |
|---|---|---|---|
| `voaaguia-local-api-1` | `voaaguia-local-api` | `Up 10 seconds` | `127.0.0.1:8080->8080/tcp` |
| `voaaguia-local-mongo-1` | `mongo:7.0` | `Up 16 seconds (healthy)` | `27017/tcp`, sem publicação no host |

A imagem comprova os dois containers ativos no instante da coleta e o healthcheck do MongoDB aprovado. A disponibilidade HTTP da API é registrada no print seguinte; `Up` sozinho não comprova seu atendimento HTTP.

## 2. Swagger local

Arquivo: [swaggerLocal.png](evidencias/swaggerLocal.png).

![Swagger local](evidencias/swaggerLocal.png)

URL visível: `http://localhost:8080/swagger-ui/index.html`. O Swagger carregou o contrato `/v3/api-docs` e apresenta **VoaÁguia - Sprint 2**, versão **2.0.0**, OAS **3.1**, com operações de estratégias e projetos. Isso registra a API local disponibilizando a documentação. A imagem não mostra chamadas autenticadas de negócio.

## 3. GitHub Actions

Arquivo: [actionsSuccess.png](evidencias/actionsSuccess.png).

![GitHub Actions](evidencias/actionsSuccess.png)

O workflow visível é **Voa Aguia - CI/CD (Render e Atlas)**. A lista contém quatro resultados verdes:

| Execução | Evento visível | Branch | Referência visível | Duração |
|---|---|---|---|---|
| `#8` | Push após merge do PR `#3`, `develop` para `main` | `main` | Commit `b45ebc5` | `4m 44s` |
| `#7` | Abertura do PR `#3`, título `Develop` | `develop` | Pull request `#3` | `1m 40s` |
| `#6` | Push após merge do PR `#2`, `feature/fixHealth` | `develop` | Commit `9c1d504` | `4m 43s` |
| `#5` | Abertura do PR `#2`, título `fixing health` | `feature/fixHealth` | Pull request `#2` | `1m 39s` |

O PNG comprova o sucesso geral dessas execuções. Pelo workflow atual, o push em `develop` seleciona staging e o push em `main` seleciona produção após `build-test`; pull requests executam somente validação. O PNG não abre os jobs nem informa a contagem de testes. O PDF complementa a lista com o job de CI na página 7 e os logs de deploy nas páginas 8–9. Os artefatos Maven remotos não estão anexados ao repositório.

Os tempos relativos como “5 minutes ago” pertencem à captura; não permitem determinar uma data absoluta de execução.

## 4. Swagger staging no Render

Arquivo: [swaggerStaging.png](evidencias/swaggerStaging.png).

![Swagger staging](evidencias/swaggerStaging.png)

URL visível: `https://esg-devops-staging.onrender.com/swagger-ui/index.html`. O campo `Servers` também aponta para esse domínio. O contrato exibido é **VoaÁguia - Sprint 2**, versão **2.0.0**. A captura registra a documentação acessível no serviço remoto de staging.

## 5. Swagger produção acadêmica no Render

Arquivo: [swaggerProducao.png](evidencias/swaggerProducao.png).

![Swagger produção](evidencias/swaggerProducao.png)

URL visível: `https://esg-devops-production.onrender.com/swagger-ui/index.html`. O campo `Servers` aponta para o domínio de produção. O contrato exibido também é **VoaÁguia - Sprint 2**, versão **2.0.0**. A captura registra a documentação acessível em um domínio diferente de staging.

Os dois PNGs remotos comprovam acesso aos Swaggers no momento da coleta. As verificações de saúde e a identificação dos commits aparecem nos logs incorporados ao PDF, não nesses PNGs. As capturas não demonstram testes manuais de todas as operações de negócio.

## 6. Evidências adicionais incorporadas ao PDF

| Página / figura | Material conferido visualmente | O que comprova |
|---|---|---|
| P. 7, figura 3 | Job `Compilar, testar e construir imagem Docker` aprovado | Etapas de checkout, preparação Java, Maven com MongoDB, Docker build e relatórios aprovadas |
| P. 8, figura 5 | Job `Deploy Render - staging`, log com SHA, `live` e mensagem final de saúde | Deploy staging concluído e verificação HTTP da API/MongoDB aprovada |
| P. 9, figura 7 | Job `Deploy Render - producao academica`, log com SHA, `live` e mensagem final de saúde | Deploy produção concluído e verificação HTTP da API/MongoDB aprovada |
| P. 10, figura 9 | Atlas Data Explorer com `voaaguia_production` e `voaaguia_staging` | Existência dos dois bancos distintos |

Essas capturas estão no [relatório PDF](Voa_Aguia_Relatorio_Tecnico_DevOps_Final.pdf), que permanece a referência dos materiais incorporados. A figura 3 não informa a quantidade de testes. As figuras 5 e 7 registram o healthcheck aprovado pelo script, sem exibir o JSON bruto da resposta. A figura 9 não mostra credenciais, permissões dos usuários, regras IP ou os valores JWT. Bancos distintos no mesmo cluster representam separação lógica.

## Relação entre implementação e evidências

| Item | Implementação no repositório | Evidência disponível |
|---|---|---|
| Containers de API e banco | `Dockerfile` e `docker-compose.yml` | Containers ativos + Swagger local |
| Compilação e testes | Job `build-test`, `clean verify`, MongoDB de teste | Job aprovado no PDF p. 7; contagem remota não informada |
| Build da imagem | `docker build --tag voaaguia:<SHA>` no CI | Etapa aprovada no PDF p. 7; container local usando imagem da API |
| Deploy staging | Job `staging`, push em `develop`, API Render | Log `live` e saúde OK no PDF p. 8, mais Swagger |
| Deploy produção | Job `production`, push em `main`, API Render | Log `live` e saúde OK no PDF p. 9, mais Swagger |
| Saúde API + banco | `/healthz` e checagem em `render-deploy.sh` | Logs finais de saúde aprovados no PDF p. 8–9 |
| Banco remoto | URI configurável por `MONGODB_URI` | Dois bancos no Data Explorer do PDF p. 10; configuração privada não exibida |

## Complementos para a entrega

Os jobs, os healthchecks e os nomes dos bancos já estão registrados no PDF. Para rastreabilidade adicional, preserve os artefatos de testes e confirme que o código no pacote final corresponde à versão pretendida. Evidências de usuários com permissões por banco e regras IP podem complementar a configuração, sem publicar URI ou credenciais.

Mantenha os cinco PNGs com seus nomes atuais e o PDF no pacote. A captura geral do Actions e as imagens incorporadas ao PDF se complementam. A revisão não fabricou novos prints de execução.

## Desafios encontrados e soluções relatadas

- **MongoDB nos testes:** a integração depende de banco real; o CI provisiona MongoDB 7.0 e a suíte usa banco temporário com nome aleatório.
- **Saúde no deploy:** o histórico do projeto registra `fixing health`; `/healthz` é público e executa `ping` no MongoDB. O script exige `live` e resposta de saúde válida.
- **Publicar o código validado:** o script usa `GITHUB_SHA` como `commitId` na API do Render.
- **Configuração de secrets:** o PDF p. 11 relata ausência inicial de `RENDER_API_KEY`, corrigida pelo repository secret mapeado no job.
- **Banco explícito na URI:** o PDF p. 11 relata `Database name must not be empty`, corrigido ao informar o banco na URI de cada ambiente.
- **Saúde bloqueada por segurança:** o PDF p. 11 relata HTTP 401 em `/healthz`; a configuração atual permite esse caminho publicamente. As capturas posteriores mostram a saúde aprovada.
- **Integração e separação de ambientes:** o PDF relata dois serviços com branches, bancos e JWT próprios; os domínios e nomes dos bancos são visualmente comprovados. Os valores privados não foram expostos.

As ocorrências históricas são atribuídas ao relato do PDF. Seus logs originais de falha não estão anexados; as capturas comprovam o resultado posterior e o código confirma a solução atual do healthcheck. Problema, causa, solução e resultado estão relacionados na seção 18 do [README](../README.md).

## Validação local da revisão anterior

A revisão anterior executou a suíte com Maven 3.9.9 e Java 17 em um container temporário, conectado a MongoDB 7.0 isolado. Os relatórios locais existentes registram **9 testes, 0 falhas, 0 erros, 0 ignorados** (8 de integração e 1 de auditoria), e o log anterior registrou **BUILD SUCCESS**. Esta contagem não é atribuída ao CI remoto do PDF.

O teste acrescentado verifica `/healthz` sem autenticação, a resposta de saúde com banco disponível e a declaração de segurança no OpenAPI: login, cadastro e saúde são públicos, enquanto `/api/auth/me` continua protegido. Os relatórios desta execução ficam em `target/surefire-reports/`, fora do Git.

Na revisão anterior também foram validados Compose, sintaxe Bash e links, e o container temporário foi removido. A padronização atual preserva esse histórico, confere os documentos e as referências e não executa novamente a aplicação ou os testes. O [relatório de auditoria](REVISAO_DOCUMENTACAO.md) registra as novas verificações documentais e a pendência do ZIP.
