# Passo a passo — Voa Águia (Windows, GitHub Actions, Render e Atlas)

O projeto usa Docker Compose localmente e dois serviços Docker no Render para staging e produção acadêmica. Este roteiro reproduz o fluxo do [PDF técnico](Voa_Aguia_Relatorio_Tecnico_DevOps_Final.pdf) e do [catálogo de evidências](EVIDENCIAS.md). A identificação dos quatro integrantes e a relação com ESG estão no [README](../README.md).

## 1. Conferir o projeto e os requisitos

Na raiz, devem existir `pom.xml`, `src`, `Dockerfile`, `docker-compose.yml`, `.env.example`, `.github/workflows`, `scripts` e `docs`. Este repositório contém o backend; acrescente outros módulos ao pacote somente se o enunciado da atividade os exigir.

No Windows, tenha Docker Desktop iniciado e Git. Java 17 é necessário para executar Maven diretamente no host; os builds Docker e do GitHub Actions já usam Java 17.

```powershell
docker --version
docker compose version
git --version
```

## 2. Configurar o ambiente local

Crie `.env` somente se ainda não existir, para preservar a configuração já utilizada:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
notepad .env
```

Defina `JWT_SECRET` com pelo menos 32 bytes aleatórios. Para gerar um valor:

```powershell
$bytes = New-Object byte[] 48
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$rng.Dispose()
[Convert]::ToBase64String($bytes)
```

Para demonstração local, `SEED_ENABLED=true` exige `SEED_PASSWORD` com 12 ou mais caracteres. Sem seed, use o cadastro da API para criar um operador. A IA é opcional e exige chave válida e modelo configurado. O `.env` é ignorado pelo Git e deve ficar fora da entrega.

## 3. Executar API e MongoDB locais

```powershell
docker compose config --quiet
docker compose up -d --build
docker compose ps
docker compose logs --tail=100 api
Invoke-RestMethod http://localhost:8080/healthz
```

Abra `http://localhost:8080/swagger-ui/index.html`. Se a porta estiver ocupada, altere `HOST_PORT` no `.env`, suba novamente e ajuste a URL. As imagens existentes são [containers locais](evidencias/containerLocal.png) e [Swagger local](evidencias/swaggerLocal.png), ambas referentes à porta 8080.

Para parar sem apagar os dados, use `docker compose down`. Evite `down -v` se pretende manter o volume MongoDB.

## 4. Executar os testes

O Compose não publica MongoDB em 27017. Para Maven no host, use uma instância nessa porta:

```powershell
docker run -d --name voaaguia-mongo-teste -p 127.0.0.1:27017:27017 mongo:7.0
docker exec voaaguia-mongo-teste mongosh --quiet --eval "db.adminCommand('ping').ok"
.\mvnw.cmd --batch-mode --no-transfer-progress clean verify
docker stop voaaguia-mongo-teste
docker rm --volumes voaaguia-mongo-teste
```

Aguarde o `ping` retornar `1` antes dos testes. Se já houver MongoDB na porta 27017, reutilize-o. A suíte de integração cria um banco de testes aleatório e o remove ao final; a auditoria usa H2. Confira `BUILD SUCCESS` e `target/surefire-reports`. Os comandos de remoção acima destinam-se somente ao container dedicado de testes e aos seus volumes anônimos.

## 5. Configurar Atlas e Render

Siga [GUIA_RENDER_ATLAS.md](GUIA_RENDER_ATLAS.md):

1. Configure bancos e usuários separados para staging e produção no Atlas.
2. Autorize os endereços de saída dos serviços Render na lista de acesso Atlas.
3. Configure dois Web Services Docker: `develop` para staging e `main` para produção.
4. Em cada serviço, informe `MONGODB_URI`, `JWT_SECRET` próprio e `SEED_ENABLED=false`.
5. Configure Health Check Path `/healthz` e Auto-Deploy `Off`.
6. Registre os IDs dos serviços e as URLs públicas para o CI.

O Render executa a imagem da API, com banco externo Atlas. A aplicação aceita a variável `PORT`. As URLs dos serviços são públicas e HTTPS. Os bancos `voaaguia_staging` e `voaaguia_production` estão registrados na página 10 do PDF.

No Render Free, a primeira requisição após inatividade pode aguardar a inicialização do serviço. Isso é uma limitação do ambiente acadêmico descrita no [guia de infraestrutura](GUIA_RENDER_ATLAS.md#limitações-da-infraestrutura-acadêmica).

## 6. Configurar GitHub

Siga [COMO_CONFIGURAR_GITHUB.md](COMO_CONFIGURAR_GITHUB.md). Cadastre `RENDER_API_KEY` como repository secret. Crie os environments `staging` e `production`; em cada um, configure as Variables `RENDER_SERVICE_ID` e `RENDER_PUBLIC_URL`.

Mantenha o remote já configurado se o projeto estiver no GitHub. Para a promoção:

1. Envie mudanças em `develop`: o Actions valida o código e publica staging.
2. Verifique staging e abra um PR de `develop` para `main`: o PR executa CI.
3. Faça merge em `main`: uma nova execução valida e publica produção.

Também é possível usar **Actions > Run workflow**, escolhendo a branch do ambiente. Em PR não há deploy. O workflow não publica staging e produção juntos em um push em `main`.

## 7. Conferir publicação e saúde

Após o job do ambiente terminar, consulte:

```powershell
Invoke-RestMethod https://esg-devops-staging.onrender.com/healthz
Invoke-RestMethod https://esg-devops-production.onrender.com/healthz
```

Abra:

- [Swagger staging](https://esg-devops-staging.onrender.com/swagger-ui/index.html).
- [Swagger produção](https://esg-devops-production.onrender.com/swagger-ui/index.html).

No Actions, confira o SHA, o status `live` e `Deploy LIVE + HTTP health check OK`. No Render, compare o commit do deploy. O script não encerra com sucesso apenas ao solicitar a publicação: aguarda sua conclusão e valida a API com o MongoDB.

## 8. Usar as evidências anexadas

As cinco imagens já estão incorporadas ao [README](../README.md) e ao [relatório de evidências](EVIDENCIAS.md). Elas incluem `docker ps`, Swagger local, execuções verdes no Actions e Swagger dos dois ambientes Render. Mantenha os nomes dos arquivos para preservar os links. O PDF acrescenta o job de CI (p. 7), logs de staging/produção com saúde OK (p. 8–9) e dois bancos Atlas (p. 10).

As figuras incorporadas ao PDF permanecem como referência. Para ampliar a rastreabilidade, guarde os artefatos Maven e compare o SHA do deploy com o código entregue. A figura Atlas confirma a existência dos bancos; permissões de usuários, regras de rede e valores JWT não aparecem nas capturas e não devem ser declarados comprovados por elas.

## 9. Preparar a entrega

O [PDF técnico](Voa_Aguia_Relatorio_Tecnico_DevOps_Final.pdf) já está disponível, com integrantes, arquitetura, pipeline, capturas, desafios e checklist. Inclua-o na entrega junto da documentação Markdown. A página 12 declara um ZIP preparado, mas nenhum ZIP foi localizado nesta pasta; a [auditoria](REVISAO_DOCUMENTACAO.md) registra a conferência como pendente.

O ZIP deve conter `src`, `pom.xml`, Maven Wrapper (`mvnw`, `mvnw.cmd`, `.mvn/wrapper`), `Dockerfile`, `docker-compose.yml`, `.env.example`, `.github/workflows`, scripts, README, documentação e evidências. Exclua arquivos `.env` reais e suas variantes privadas, chaves, credenciais, `.git` e `target`. Preserve a identificação acadêmica fornecida. Confira o conteúdo e sua correspondência com a versão de código pretendida antes de enviar.

## Problemas comuns

| Sintoma | Como conferir |
|---|---|
| Docker indisponível | Inicie Docker Desktop e confirme `docker version` |
| Porta 8080 ocupada | Altere `HOST_PORT` e a URL local |
| API local reiniciando | Consulte logs; valide segredo JWT e senha de seed |
| Testes não conectam ao banco | MongoDB de testes deve responder em `localhost:27017` |
| Variável ausente no deploy | Confira Secrets/Variables do environment correto |
| Banco indisponível no Render | Confira `MONGODB_URI`, usuário e lista de acesso Atlas |
| Swagger abre, mas deploy falha | Confira `/healthz`, que também depende de MongoDB |
| IA retorna 503 | Configure a chave se precisar demonstrar os endpoints de IA |
