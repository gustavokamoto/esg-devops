# Voa Águia — Backend | Desafio DevOps

**Projeto:** Voa Águia. O nome “Cidades ESG Inteligentes” era apenas um exemplo no enunciado, não é o nome deste projeto.

Este repositório contém o **backend Java Spring Boot** recebido para o desafio e os arquivos de automação DevOps. Caso o aplicativo também possua um frontend ou projeto Android em outra pasta, esse código deve ser anexado à entrega completa à parte ou incorporado à estrutura final: ele **não estava no ZIP de backend enviado**.

**Leitura obrigatória para executar e entregar:** [docs/PASSO_A_PASSO.md](docs/PASSO_A_PASSO.md).

## Como executar localmente com Docker

**Requisitos:** Docker Desktop com Docker Compose. Na pasta em que estão `Dockerfile` e `docker-compose.yml`:

```powershell
Copy-Item .env.example .env
notepad .env
```

Altere `JWT_SECRET` para um valor aleatório com no mínimo 32 bytes (pode gerar com `python -c "import secrets; print(secrets.token_urlsafe(48))"`). Para dados de demonstração opcionais, defina `SEED_ENABLED=true` e uma senha de **12 ou mais caracteres** em `SEED_PASSWORD`. Nunca compartilhe `.env` ou suas senhas.

```powershell
docker compose config
docker compose up -d --build
docker compose ps
docker compose logs --tail=100 api
```

**Swagger:** http://localhost:8080/swagger-ui/index.html  
**Contrato OpenAPI:** http://localhost:8080/v3/api-docs

Para desligar sem apagar dados: `docker compose down`. **Não** use `down -v` se quiser preservar dados. O MongoDB persiste no volume Docker `mongo_data`.

### Testes

Os testes existentes em `src/test/` usam uma instância MongoDB acessível em `localhost:27017`; no GitHub Actions o serviço é criado automaticamente. Para executar localmente com Java 17 disponível:

```powershell
docker run -d --name voaaguia-mongo-teste -p 27017:27017 mongo:7.0
.\mvnw.cmd clean verify
docker stop voaaguia-mongo-teste
docker rm voaaguia-mongo-teste
```

Se a porta 27017 já estiver ocupada, reutilize uma instância MongoDB já acessível nessa porta ou encerre-a antes de criar outra.

## Pipeline CI/CD

**Ferramenta:** GitHub Actions, arquivo `.github/workflows/ci-cd.yml`.

| Disparo | Build | Testes | Docker build | Staging | Produção |
|---|---|---|---|---|---|
| Pull request em `develop` ou `main` | Sim | Sim | Sim | Não | Não |
| Push em `develop` | Sim | Sim | Sim | Sim | Não |
| Push em `main` | Sim | Sim | Sim | Sim | Sim, após staging |

O pipeline usa Java 17, Maven e um serviço temporário MongoDB para executar os testes e gerar a imagem Docker. Depois copia os arquivos para **um servidor Linux persistente**, conecta via SSH, executa `docker compose up -d --build` no diretório do ambiente e verifica `GET /v3/api-docs`.

**Atenção:** configurar um arquivo YAML não prova um deploy realizado. É necessário um servidor acessível, ambientes `staging`/`production` no GitHub, secrets de SSH e `.env` separados no servidor. Veja a configuração completa em [docs/PASSO_A_PASSO.md](docs/PASSO_A_PASSO.md) e [docs/COMO_CONFIGURAR_GITHUB.md](docs/COMO_CONFIGURAR_GITHUB.md).

## Containerização

**Dockerfile** (multi-stage: compila com Maven/JDK 17 e executa com JRE 17):

```dockerfile
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY pom.xml .
RUN mvn -q dependency:go-offline
COPY src src
RUN mvn -q package -DskipTests
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /workspace/target/backend-2.0.0.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
```

**Docker Compose** (`docker-compose.yml`): serviços `api` (Spring Boot) e `mongo` (MongoDB 7), rede isolada `voaaguia_network`, volume `mongo_data`, healthcheck MongoDB e configurações por variáveis (`JWT_SECRET`, `MONGO_DATABASE`, `HOST_PORT`, `SEED_ENABLED`, `GEMINI_API_KEY`). A imagem é criada com `docker compose build api` (ou `docker build -t voaaguia:local .`).

Por segurança, a API é publicada por padrão em `127.0.0.1` (`HOST_BIND_IP`), inclusive no servidor; para demonstrar remotamente, use túnel SSH. Os dois ambientes compartilham o código, mas têm **projetos Compose, bancos, portas, variáveis e volumes distintos**.

**Limitação conhecida:** a trilha de auditoria JPA usa H2 em memória; esses eventos são perdidos ao reiniciar a API. Os dados principais são persistidos no MongoDB.

## Prints do funcionamento

**Inclua evidências reais após executar**, não prints simulados. Armazene-as em `docs/evidencias/` e referencie os arquivos ou URLs aqui:

| Evidência exigida | Arquivo sugerido | Status |
|---|---|---|
| Containers locais | `01-compose-local.png` | Pendente |
| Swagger local | `02-swagger-local.png` | Pendente |
| Actions — build/teste | `03-actions-build-test.png` | Pendente |
| Actions — deploy staging | `04-actions-staging.png` | Pendente |
| Swagger staging | `05-staging.png` | Pendente |
| Actions — deploy produção | `06-actions-production.png` | Pendente |
| Swagger produção | `07-production.png` | Pendente |
| Serviços dos dois ambientes | `08-compose-ambientes.png` | Pendente |

Orientações: [docs/EVIDENCIAS.md](docs/EVIDENCIAS.md).

## Tecnologias utilizadas

Java 17; Spring Boot 3.5.6; Maven; Spring Security e JWT; Spring Data MongoDB; MongoDB 7; Spring Data JPA/Hibernate + H2 em memória; springdoc/Swagger/OpenAPI; JUnit 5 e Spring Boot Test; Docker multi-stage; Docker Compose; Git e GitHub; GitHub Actions; SSH/SCP; Linux para hospedagem.

## Principais desafios técnicos

1. **Testes dependem de MongoDB real:** o pipeline inicia um serviço MongoDB dedicado para os testes.
2. **Separar staging e produção:** pastas e `.env` distintos garantem dados, portas e volumes independentes.
3. **Evitar vazamento de credenciais:** `.env` fica fora do Git; GitHub Environment Secrets guardam a chave SSH.
4. **Comprovar a implantação:** o pipeline faz requisição HTTP ao endpoint OpenAPI após o `docker compose up`.

Registre os problemas e as soluções **efetivamente ocorridos na sua execução** no PDF/PPT final.

## Checklist de entrega (preencher após validar)

- [ ] ZIP com estrutura organizada e todo o código exigido na atividade
- [ ] Dockerfile funcional (testado)
- [ ] `docker-compose.yml` funcional com app e MongoDB
- [ ] Pipeline GitHub Actions com build, testes e deploy
- [ ] README com instruções e prints reais
- [ ] Documentação técnica final em PDF ou PPT com evidências
- [ ] Deploy validado em staging e produção

**Não marque como concluído apenas porque o arquivo de configuração existe.**
