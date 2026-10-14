# Voa Águia — Navegando pelo Mundo DevOps

## 1. Apresentação do Voa Águia

O **Voa Águia** é um backend REST em Java Spring Boot para gerir estratégias, ideias e projetos de inovação. A API oferece autenticação JWT, autorização por perfil, histórico de estratégias, acompanhamento de projetos, indicadores e integração opcional com Google Gemini.

Esta entrega da FIAP demonstra integração contínua, testes automatizados, containerização e deploy em staging e produção acadêmica. O [relatório técnico em PDF](docs/Voa_Aguia_Relatorio_Tecnico_DevOps_Final.pdf), de 13 de outubro de 2026, organiza a entrega e suas evidências. O código e as configurações atuais definem o comportamento técnico. A comparação detalhada está em [docs/REVISAO_DOCUMENTACAO.md](docs/REVISAO_DOCUMENTACAO.md).

O título exibido no Swagger é **VoaÁguia - Sprint 2**, versão `2.0.0`. Os nomes dos serviços Render começam com `esg-devops`; o nome oficial da aplicação é **Voa Águia**.

## 2. Integrantes

- Mirella Ayumi Miyakawa
- Gustavo Okamoto Ventura
- Davi Simplicio Nunes Coelho
- Guilherme Vinicius Gonçalves da Silva

## 3. Objetivo e relação com ESG

A aplicação organiza propostas vinculadas a estratégias, permite avaliação por gestores, converte ideias aprovadas em projetos e acompanha investimento, retorno, redução de custos, ganho de produtividade e prazos. Líderes consultam dashboard e histórico; operadores submetem ideias e participam do ranking.

Esse fluxo pode apoiar iniciativas ESG: propostas de eficiência e redução de desperdícios no eixo ambiental; participação dos colaboradores no eixo social; permissões, histórico e critérios de acompanhamento no eixo de governança. Trata-se de aplicação possível do modelo de inovação. O backend não implementa inventário de emissões, certificação ESG ou medição específica de impacto socioambiental. Os prints comprovam execução técnica, sem demonstrar resultados quantitativos de sustentabilidade.

## 4. Tecnologias utilizadas

| Tecnologia | Versão/configuração verificada | Finalidade |
|---|---|---|
| Java | 17 | Compilação e execução |
| Spring Boot | 3.5.6 | API REST, configuração e integração de componentes |
| Maven | 3.9.9 no Wrapper e na imagem de build | Dependências, testes e empacotamento |
| Spring Security / OAuth2 Resource Server | Gerenciados pelo Spring Boot | JWT HS256 e autorização por perfil |
| Spring Data MongoDB | Gerenciado pelo Spring Boot | Persistência dos dados de negócio |
| MongoDB | Imagem `mongo:7.0` local e no CI; Atlas remoto | Banco de dados |
| Spring Data JPA / Hibernate | Starter JPA 3.5.6; Hibernate gerenciado | Auditoria de login e cadastro |
| H2 | 2.3.232, em memória | Banco de auditoria |
| springdoc / Swagger / OpenAPI | springdoc 2.8.13; contrato OAS 3.1 nas capturas | Documentação interativa |
| JUnit / Spring Boot Test / Security Test | Dependências de teste gerenciadas pelo Spring Boot | Testes automatizados |
| Docker / Docker Compose | Dockerfile multiestágio; Compose com dois serviços | Containerização local e imagem da API |
| GitHub Actions | Workflow `ci-cd.yml` | CI e acionamento de CD |
| Render / MongoDB Atlas | Dois Web Services; dois bancos em cluster compartilhado, conforme PDF | Aplicação e persistência remotas |
| Google Gemini | Opcional, configurado por variáveis | Sugestões e análises assistidas |

As versões estão em [pom.xml](pom.xml), [Maven Wrapper](.mvn/wrapper/maven-wrapper.properties), [Dockerfile](Dockerfile) e [Compose](docker-compose.yml). Dependências gerenciadas não têm versão fixada individualmente no `pom.xml`.

## 5. Arquitetura da aplicação

```mermaid
flowchart TD
    Local[Docker Compose local] --> API[api: Spring Boot / Java 17]
    API --> Mongo[mongo: MongoDB 7.0 / volume mongo_data]
    Git[GitHub: develop e main] --> CI[Actions: Maven verify e Docker build]
    CI -->|develop| Staging[Render: staging]
    CI -->|main| Production[Render: produção acadêmica]
    Staging --> StagingDB[Atlas: voaaguia_staging]
    Production --> ProductionDB[Atlas: voaaguia_production]
```

| Ambiente | Serviço / acesso Swagger | Persistência e configuração |
|---|---|---|
| Local | `api` e `mongo`; [localhost:8080](http://localhost:8080/swagger-ui/index.html) | Banco `voaaguia_sprint2` por padrão; `.env` local; volume Docker |
| Staging | `esg-devops-staging`; [Swagger HTTPS](https://esg-devops-staging.onrender.com/swagger-ui/index.html) | `voaaguia_staging` no Atlas; branch `develop`; variáveis próprias no Render |
| Produção acadêmica | `esg-devops-production`; [Swagger HTTPS](https://esg-devops-production.onrender.com/swagger-ui/index.html) | `voaaguia_production` no Atlas; branch `main`; variáveis próprias no Render |

Staging e produção são serviços distintos, com configuração independente de `MONGODB_URI` e `JWT_SECRET`, conforme o PDF, páginas 3, 10 e 11. Os bancos compartilham o cluster Atlas; a separação é lógica, não entre clusters físicos. Usuários de banco e permissões restritos por ambiente são recomendados, mas não aparecem nas capturas.

A auditoria JPA usa H2 em memória e perde seus eventos quando a API reinicia. Os dados de negócio são persistidos no MongoDB. No Render Free, serviços podem suspender após 15 minutos sem tráfego e levar aproximadamente um minuto para iniciar ao receber nova requisição; o sistema de arquivos é efêmero e há cotas compartilhadas de uso. O ambiente serve à demonstração acadêmica, sem garantia de alta disponibilidade comercial. Consulte [limitações oficiais do Render Free](https://render.com/docs/free).

## 6. Estrutura de diretórios

```text
.
├── .github/workflows/ci-cd.yml       # CI e deploy por ambiente
├── .mvn/wrapper/                    # Configuração do Maven Wrapper
├── docs/
│   ├── Voa_Aguia_Relatorio_Tecnico_DevOps_Final.pdf
│   ├── COMO_CONFIGURAR_GITHUB.md
│   ├── GUIA_RENDER_ATLAS.md
│   ├── PASSO_A_PASSO.md
│   ├── EVIDENCIAS.md
│   ├── REVISAO_DOCUMENTACAO.md
│   └── evidencias/                  # Cinco PNGs originais e índice
├── scripts/render-deploy.sh
├── src/main/java/com/voaaguia/      # API, serviços, segurança, domínio e persistência
├── src/main/resources/application.yml
├── src/test/java/com/voaaguia/      # Integração HTTP/MongoDB e auditoria JPA
├── .env.example
├── Dockerfile
├── docker-compose.yml
├── mvnw / mvnw.cmd
├── pom.xml
└── run-local.ps1                    # Execução Maven no Windows, sem container da API
```

O repositório contém o backend. `target/` é gerado pelo Maven e ignorado pelo Git.

## 7. Pré-requisitos

Para execução local com containers: Docker Desktop iniciado, suporte a containers Linux e Docker Compose. Para Maven no host: JDK 17, acesso às dependências e MongoDB acessível em `localhost:27017`. O Wrapper fornece o Maven; não é necessária instalação separada.

Para reproduzir a nuvem: repositório GitHub, dois serviços Render e cluster Atlas com acesso de rede e usuários configurados. Os runners do GitHub Actions são temporários; a API fica hospedada no Render.

```powershell
docker version
docker compose version
git --version
# Necessário somente para Maven no host:
java -version
```

## 8. Configuração de variáveis de ambiente

Crie a configuração local sem sobrescrever um `.env` existente:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
notepad .env
```

| Variável | Uso / valor de exemplo |
|---|---|
| `COMPOSE_PROJECT_NAME` | Local: `voaaguia-local`; prefixa recursos Compose |
| `HOST_BIND_IP` | Local: `127.0.0.1`; endereço de publicação no host |
| `HOST_PORT` | Local: `8080`; porta do host para a API |
| `MONGO_DATABASE` | Local: `voaaguia_sprint2`; usado pelo Compose para montar a URI |
| `MONGODB_URI` | Render: URI Atlas com banco explícito; no Compose é montada automaticamente |
| `JWT_SECRET` | Obrigatório: segredo aleatório de pelo menos 32 bytes UTF-8; distinto por ambiente |
| `PORT` | Porta interna Spring Boot; padrão `8080`, fornecida pela plataforma no Render |
| `SEED_ENABLED` | Padrão `false`; `true` somente para demonstração local |
| `SEED_PASSWORD` | Obrigatória com seed: pelo menos 12 caracteres |
| `GEMINI_API_KEY` | Opcional; ausência produz 503 nos endpoints autorizados de IA |
| `GEMINI_MODEL` | Modelo escolhido explicitamente para a integração opcional |

Para gerar o segredo JWT no PowerShell:

```powershell
$bytes = New-Object byte[] 48
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$rng.Dispose()
[Convert]::ToBase64String($bytes)
```

O [.env.example](.env.example) contém apenas valores de exemplo, sem credenciais reais. A URI Atlas autenticada, senha de seed, chave Gemini e segredo JWT ficam em configuração privada. `RENDER_API_KEY` pertence ao GitHub, não às variáveis da aplicação.

**Divergência técnica preservada:** Compose e `.env.example` usam `gemini-2.5-flash`; `application.yml` usa `gemini-3.6-flash` quando `GEMINI_MODEL` não está definida. Configure a variável explicitamente e confirme a disponibilidade do modelo no provedor antes de demonstrar IA. Esta documentação registra os valores do código, sem validar o serviço externo.

## 9. Como executar localmente com Docker

Na raiz, após configurar `.env`:

```powershell
docker compose config --quiet
docker compose up -d --build
docker compose ps
docker compose logs --tail=100 api
Invoke-RestMethod http://localhost:8080/healthz
```

Abra [Swagger local](http://localhost:8080/swagger-ui/index.html). A resposta esperada de saúde é `{"status":"UP","application":"voaaguia"}`. Se a porta estiver ocupada, altere `HOST_PORT` no `.env`, execute novamente `up -d --build` e ajuste a URL.

Para reconstruir a API após mudanças de código:

```powershell
docker compose up -d --build api
```

Para parar preservando o banco:

```powershell
docker compose down
```

`docker compose down -v` remove o volume do banco; use-o apenas quando quiser excluir os dados locais. Consulte o [roteiro completo](docs/PASSO_A_PASSO.md).

## 10. Como executar os testes automatizados

A suíte de integração usa HTTP real e MongoDB em `localhost:27017`, com banco aleatório `voaaguia_test_*`, removido ao final. O Compose não publica MongoDB no host; com JDK 17, inicie uma instância dedicada, sem reutilizar dados de staging/produção:

```powershell
docker run -d --name voaaguia-mongo-teste -p 127.0.0.1:27017:27017 mongo:7.0
docker exec voaaguia-mongo-teste mongosh --quiet --eval "db.adminCommand('ping').ok"
.\mvnw.cmd --batch-mode --no-transfer-progress clean verify
docker stop voaaguia-mongo-teste
docker rm --volumes voaaguia-mongo-teste
```

Aguarde o `ping` retornar `1` antes do Maven; repita a verificação enquanto o banco inicia. Se a porta já tiver uma instância adequada, reutilize-a. Os dois últimos comandos removem somente o container dedicado e seus volumes anônimos de teste.

Os testes cobrem autenticação, autorização, cadastro sem promoção de perfil, propriedade e exclusão lógica de ideias, fluxo de projetos, dashboard, histórico, revogação JWT, saúde/OpenAPI e resposta de IA sem chave. O teste de auditoria usa H2.

Relatórios: `target/surefire-reports/`; no Actions, artefato `testes-<número da execução>`. Os relatórios locais já existentes registram **9 testes, sem falhas ou erros**, executados na revisão anterior. O PDF, página 7, comprova o job CI aprovado, sem informar sua contagem. Esta padronização documental não executou novos testes.

## 11. Containerização e Dockerfile

O [Dockerfile](Dockerfile) compila em `maven:3.9.9-eclipse-temurin-17` e executa o JAR em `eclipse-temurin:17-jre`. Copia primeiro `pom.xml` para preparar dependências, depois `src`, empacota `backend-2.0.0.jar` e inicia `java -jar app.jar`.

```powershell
docker build -t voaaguia:local .
docker compose build api
```

O estágio de build usa `package -DskipTests`. No CI os testes são executados antes do Docker build. O workflow constrói a imagem `voaaguia:<SHA>` para validação, sem publicação em registry; o Render reconstrói sua imagem a partir do commit solicitado.

## 12. Docker Compose: aplicação, banco, redes e volumes

| Recurso | Configuração real |
|---|---|
| `api` | Build pelo Dockerfile, `restart: unless-stopped`, variáveis da API e porta interna 8080 |
| `mongo` | `mongo:7.0`, `restart: unless-stopped`, sem porta publicada no host |
| Dependência | `api` aguarda `mongo` com `condition: service_healthy` |
| Healthcheck MongoDB | `mongosh` com `ping`, intervalo 5s, timeout 5s, 20 tentativas e início 10s |
| Rede | `voaaguia_network`, driver `bridge` |
| Volume | `mongo_data:/data/db`, persistência do banco local |
| Porta publicada | `127.0.0.1:8080:8080` por padrão, configurável |

O Compose monta `MONGODB_URI=mongodb://mongo:27017/<MONGO_DATABASE>`. O serviço Render usa outra URI, configurada em seu painel, sem executar o Compose local. O Compose possui healthcheck para o banco; não possui healthcheck Docker para a API. `/healthz` é verificado pelo script de deploy e pode ser consultado localmente.

```powershell
docker compose ps
docker ps
docker compose logs --tail=100 api
docker compose logs --tail=100 mongo
```

## 13. Pipeline CI/CD com GitHub Actions

Workflow: [ci-cd.yml](.github/workflows/ci-cd.yml), **Voa Aguia - CI/CD (Render e Atlas)**.

| Evento | CI: Maven e Docker build | CD |
|---|---|---|
| PR com destino `develop` ou `main` | Sim | Sem deploy |
| Push em `develop` | Sim | Staging após `build-test` |
| Push em `main` | Sim | Produção após `build-test` |
| Execução manual em `develop` / `main` | Sim | Ambiente correspondente |
| Execução manual em outra branch | Sim | Sem deploy |

O job `build-test` usa `ubuntu-latest`, checkout, Java 17 Temurin com cache Maven, MongoDB 7.0 com healthcheck, `bash ./mvnw --batch-mode --no-transfer-progress clean verify` e `docker build --tag voaaguia:${{ github.sha }} .`. A etapa de upload usa `if: always()` e publica relatórios quando presentes; a ausência de arquivos é ignorada.

Os jobs `staging` e `production` têm `needs: build-test`, environments próprios, limite de 35 minutos e `concurrency` por ambiente com `cancel-in-progress: false`. Cada um chama [render-deploy.sh](scripts/render-deploy.sh) com secret/variables do GitHub. A permissão do workflow é `contents: read`.

CI aprova compilação, testes e construção da imagem. CD solicita o SHA aprovado como `commitId`, acompanha o deploy até `live` e exige `/healthz` com `status=UP` e `application=voaaguia`. Variável ausente, resposta HTTP inválida, ID de deploy ausente, falha do Render, esgotamento das consultas ou healthcheck inválido interrompem o script.

A produção depende de `build-test`, não do job staging. Validar `develop` e promovê-la por PR para `main` é o processo de trabalho descrito no PDF; o YAML não obriga que todo push em `main` tenha passado por staging. Detalhes e critérios: [COMO_CONFIGURAR_GITHUB.md](docs/COMO_CONFIGURAR_GITHUB.md).

## 14. Deploy em staging e produção

Configure dois Web Services Docker: `esg-devops-staging` ligado a `develop` e `esg-devops-production` ligado a `main`. Ambos usam `./Dockerfile`, `/healthz`, variáveis próprias e a porta `PORT` aceita por `application.yml`. Para concentrar a publicação no Actions após CI, configure Auto-Deploy `Off` no Render; essa configuração de painel não aparece nas capturas.

| Configuração GitHub | Escopo | Valor a informar |
|---|---|---|
| Secret `RENDER_API_KEY` | Repository secret | Chave autorizada para acessar os serviços Render |
| Variable `RENDER_SERVICE_ID` | Environment `staging` / `production` | ID `srv-...` do serviço correspondente |
| Variable `RENDER_PUBLIC_URL` | Environment `staging` / `production` | URL base HTTPS do serviço, sem caminhos |

A referência `${{ secrets.RENDER_API_KEY }}` aceita o repository secret indicado no PDF. Um environment secret de mesmo nome pode sobrescrevê-lo; não é obrigatório duplicar a chave nos dois environments. As variáveis são lidas por `vars`, não por `secrets`.

O script consulta o Render até 90 vezes, com pausa de 15 segundos, além do tempo das requisições. Após `live`, repete a checagem HTTP conforme a política de retry do `curl`. Uma nova execução manual usa a branch escolhida. Consulte [GUIA_RENDER_ATLAS.md](docs/GUIA_RENDER_ATLAS.md).

## 15. MongoDB Atlas

O PDF, página 10, figura 9, mostra `voaaguia_staging` e `voaaguia_production` no Data Explorer. Cada serviço deve usar sua URI com banco explícito:

```text
mongodb+srv://USUARIO:SENHA_CODIFICADA@HOST_DO_CLUSTER/voaaguia_staging?retryWrites=true&w=majority
mongodb+srv://OUTRO_USUARIO:OUTRA_SENHA_CODIFICADA@HOST_DO_CLUSTER/voaaguia_production?retryWrites=true&w=majority
```

Essas strings são placeholders. Codifique caracteres reservados da senha, configure usuários com `readWrite` no respectivo banco e autorize os endereços de saída Render na lista IP do Atlas. A captura confirma os bancos, mas não confirma usuários distintos, regras de rede ou valores de autenticação, que permanecem privados. O cluster compartilhado não representa isolamento físico nem capacidade independente por ambiente.

## 16. Documentação da API com Swagger

| Ambiente | Swagger | Contrato / saúde |
|---|---|---|
| Local | [Swagger](http://localhost:8080/swagger-ui/index.html) | [OpenAPI](http://localhost:8080/v3/api-docs) / [healthz](http://localhost:8080/healthz) |
| Staging | [Swagger](https://esg-devops-staging.onrender.com/swagger-ui/index.html) | [OpenAPI](https://esg-devops-staging.onrender.com/v3/api-docs) / [healthz](https://esg-devops-staging.onrender.com/healthz) |
| Produção | [Swagger](https://esg-devops-production.onrender.com/swagger-ui/index.html) | [OpenAPI](https://esg-devops-production.onrender.com/v3/api-docs) / [healthz](https://esg-devops-production.onrender.com/healthz) |

Login (`POST /api/auth/login`), cadastro (`POST /api/auth/register`), `/healthz` e documentação são públicos. As demais rotas exigem JWT. Use o token retornado no login em **Authorize** do Swagger; a API valida também o perfil.

| Perfil | Operações principais |
|---|---|
| `OPERADOR` | Cadastrar e editar ideias próprias pendentes |
| `GESTOR` | Avaliar ideias, criar/atualizar projetos e usar IA de ideias |
| `LIDER` | Gerir estratégias, consultar dashboard e IA de indicadores |

O cadastro público cria `OPERADOR`. Para demonstração local, seed gera `operador@voaaguia.local`, `gestor@voaaguia.local` e `lider@voaaguia.local` com a senha definida em `.env`. Em serviços públicos, mantenha seed desligado e prepare perfis administrativos por procedimento controlado no banco. JWTs têm duração configurada de 60 minutos e logout registra revogação no MongoDB.

## 17. Evidências de funcionamento

| Requisito | Evidência disponível |
|---|---|
| Docker local | [containerLocal.png](docs/evidencias/containerLocal.png); PDF p. 6, figura 1 |
| Swagger local | [swaggerLocal.png](docs/evidencias/swaggerLocal.png); PDF p. 6, figura 2 |
| Build, testes e imagem | PDF p. 7, figura 3, job aprovado |
| Histórico CI/CD | [actionsSuccess.png](docs/evidencias/actionsSuccess.png); PDF p. 7, figura 4 |
| Deploy staging / saúde | PDF p. 8, figura 5, `live` e healthcheck OK |
| Swagger staging | [swaggerStaging.png](docs/evidencias/swaggerStaging.png); PDF p. 8, figura 6 |
| Deploy produção / saúde | PDF p. 9, figura 7, `live` e healthcheck OK |
| Swagger produção | [swaggerProducao.png](docs/evidencias/swaggerProducao.png); PDF p. 9, figura 8 |
| Bancos Atlas separados | PDF p. 10, figura 9 |

As capturas adicionais estão incorporadas ao PDF e são referenciadas nele; não foram criadas imagens substitutas. Os PNGs registram o momento da coleta, sem garantir disponibilidade contínua ou equivalência do commit remoto com mudanças locais posteriores.

### Containers locais

![API e MongoDB em execução](docs/evidencias/containerLocal.png)

### Swagger local

![Swagger local](docs/evidencias/swaggerLocal.png)

### GitHub Actions

![Histórico de execuções verdes](docs/evidencias/actionsSuccess.png)

### Swagger staging

![Swagger staging no Render](docs/evidencias/swaggerStaging.png)

### Swagger produção

![Swagger produção acadêmica no Render](docs/evidencias/swaggerProducao.png)

A descrição completa e os limites da comprovação estão em [EVIDENCIAS.md](docs/EVIDENCIAS.md).

## 18. Desafios encontrados e soluções

As ocorrências abaixo estão relatadas na página 11 do PDF. As capturas de sucesso confirmam o resultado posterior; os logs originais das falhas não estão anexados.

| Problema | Causa relatada / identificada | Solução aplicada no relato | Resultado / confirmação |
|---|---|---|---|
| Ausência de `RENDER_API_KEY` | Chave não disponível ao job | Cadastrar repository secret e mapear no `env` do job | Mapeamento no YAML; jobs de deploy aprovados no PDF |
| `Database name must not be empty` | URI sem banco explícito | Acrescentar banco à `MONGODB_URI` de cada serviço | Dois bancos na p. 10 e healthchecks aprovados nas p. 8–9 |
| HTTP 401 em `/healthz` | Endpoint interceptado pelo Spring Security | Adicionar `/healthz` aos caminhos públicos | `SecurityConfig` atual permite o endpoint; logs de saúde aprovados |
| Integração Render/Atlas | Aplicação remota depende de conexão externa | Definir URI por serviço, com banco explícito; conferir rede e acesso | Logs de saúde e bancos no PDF; regras privadas não capturadas |
| Separação staging/produção | Evitar compartilhar destino e configuração entre ambientes | Dois serviços, branches, bancos e configurações JWT independentes | Workflow, domínios e bancos confirmados; valores JWT não expostos |
| Deploy do código validado | Publicar versão associada ao CI | `needs: build-test` e `commitId=GITHUB_SHA` | Implementação do script e logs de deploy no PDF |

## 19. Solução de problemas frequentes

| Sintoma | Verificação / ação |
|---|---|
| Docker indisponível | Inicie Docker Desktop; confira `docker version` |
| Porta local ocupada | Ajuste `HOST_PORT`, reconstrua e atualize a URL |
| API local reiniciando | Veja logs de `api`; confira JWT e senha do seed |
| Teste não conecta ao banco | Verifique MongoDB pronto em `localhost:27017` |
| Variável ausente no deploy | Confira repository secret e variables no environment selecionado |
| Banco vazio na URI | Inclua o nome após o host da connection string Atlas |
| Conexão Atlas falha | Confira usuário, senha codificada, permissões e lista IP |
| Healthcheck retorna 401 | Confira o código implantado e o caminho `/healthz` em `SecurityConfig` |
| Swagger abre e saúde falha | Swagger não consulta o banco; `/healthz` executa `ping` |
| Primeira chamada remota demora | Considere a inicialização após inatividade do Render Free |
| IA retorna 503 ou 502 | Confira chave e modelo explícito; os prints não validam a integração Gemini |

## 20. Checklist da atividade

| Item obrigatório FIAP | Status | Base da verificação |
|---|---|---|
| Projeto compactado em ZIP com estrutura organizada | Pendente de conferência | O PDF p. 12 informa ZIP preparado; nenhum ZIP foi encontrado nesta pasta |
| Dockerfile funcional | Concluído | Arquivo, container local e job Docker build no PDF |
| Docker Compose ou configuração Kubernetes | Concluído | Compose com API, banco, rede, volume e evidência local |
| Pipeline com build, testes e deploy | Concluído | Workflow e jobs aprovados nas p. 7–9 do PDF |
| README com instruções e evidências | Concluído | Este README, PNGs e referências ao PDF |
| Documentação técnica em PDF | Concluído | Relatório presente, 12 páginas com figuras e integrantes |
| Deploy realizado em staging | Concluído nas evidências | PDF p. 8: `live`, saúde OK e Swagger |
| Deploy realizado em produção | Concluído nas evidências | PDF p. 9: `live`, saúde OK e Swagger |

O pacote final precisa conter código, Wrapper, configurações, scripts, documentação e evidências, excluindo `.env`, credenciais, `.git` e `target`. O PDF marca o ZIP como concluído; esta revisão mantém a conferência pendente até o arquivo ser disponibilizado. As execuções comprovadas pertencem aos commits registrados nas capturas, não a uma nova publicação desta revisão.

## 21. Referência à documentação técnica em PDF

[**Relatório técnico DevOps — Voa Águia**](docs/Voa_Aguia_Relatorio_Tecnico_DevOps_Final.pdf), 13 de outubro de 2026, 12 páginas. Apresenta integrantes, objetivo e ESG, arquitetura, Docker, CI/CD, evidências locais/remotas/Atlas, desafios e checklist.

A organização e as evidências deste README seguem o PDF; detalhes de versões, variáveis, comandos e regras de publicação foram conferidos no repositório. Divergências, validações e pendências estão registradas em [REVISAO_DOCUMENTACAO.md](docs/REVISAO_DOCUMENTACAO.md).
