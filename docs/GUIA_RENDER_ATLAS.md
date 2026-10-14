# Guia Render e MongoDB Atlas — Voa Águia

Este guia descreve a configuração compatível com `.github/workflows/ci-cd.yml` e `scripts/render-deploy.sh`. O [PDF técnico](Voa_Aguia_Relatorio_Tecnico_DevOps_Final.pdf), páginas 3 e 10, registra dois serviços Render e os bancos `voaaguia_staging` e `voaaguia_production` em um cluster Atlas compartilhado. As capturas não mostram usuários, credenciais ou regras de rede. Integrantes e finalidade acadêmica estão no [README](../README.md).

## 1. Preparar o Atlas

Crie ou use um cluster MongoDB Atlas. Os nomes dos bancos abaixo estão confirmados na figura 9 do PDF. Os nomes de usuários são exemplos para configurar permissões separadas:

| Ambiente | Banco registrado | Usuário de exemplo | Permissão recomendada |
|---|---|---|---|
| Staging | `voaaguia_staging` | `voaaguia_staging_app` | `readWrite` somente nesse banco |
| Produção | `voaaguia_production` | `voaaguia_production_app` | `readWrite` somente nesse banco |

A aplicação cria índices em suas coleções, incluindo unicidade de email, vínculo de projeto com ideia e expiração de tokens revogados. O usuário do banco precisa permitir essas operações.

Em **Database Access**, configure os usuários de banco com senhas diferentes. Em **Network Access**, autorize os endereços de saída de cada serviço Render. O painel do Render informa suas faixas de saída; elas precisam constar na lista de acesso do Atlas. Consulte [endereços de saída do Render](https://render.com/docs/outbound-ip-addresses) e [lista de acesso IP do Atlas](https://www.mongodb.com/docs/atlas/security/ip-access-list/).

Em **Connect > Drivers**, obtenha a connection string e informe explicitamente o banco do ambiente:

```text
mongodb+srv://USUARIO:SENHA_CODIFICADA@HOST_DO_CLUSTER/voaaguia_staging?retryWrites=true&w=majority
mongodb+srv://OUTRO_USUARIO:OUTRA_SENHA_CODIFICADA@HOST_DO_CLUSTER/voaaguia_production?retryWrites=true&w=majority
```

Substitua os placeholders e codifique caracteres reservados da senha conforme o formato URI. Guarde essas strings apenas nas variáveis protegidas dos serviços. Não as coloque no README, nos prints ou no Git.

## 2. Configurar dois Web Services Docker no Render

Para cada ambiente, conecte o repositório GitHub e configure:

| Campo | Staging | Produção acadêmica |
|---|---|---|
| Nome registrado nas capturas | `esg-devops-staging` | `esg-devops-production` |
| Branch | `develop` | `main` |
| Runtime / Language | Docker | Docker |
| Dockerfile Path | `./Dockerfile` | `./Dockerfile` |
| Docker Context | Raiz do repositório | Raiz do repositório |
| Health Check Path | `/healthz` | `/healthz` |
| Auto-Deploy | `Off`, para deploy controlado pelo Actions | `Off`, para deploy controlado pelo Actions |

O Render pode construir a imagem diretamente do Dockerfile do repositório; veja [Docker no Render](https://render.com/docs/docker). Use o comando de execução da imagem (`java -jar app.jar`), sem override adicional. O Compose com MongoDB é usado localmente, não como configuração do Web Service.

A API usa `server.port: ${PORT:8080}`. Isso permite usar a porta fornecida pelo Render; não copie `HOST_PORT` nem `HOST_BIND_IP` do Compose para esses serviços. A plataforma requer que o servidor aceite conexões em `0.0.0.0`; a aplicação não configura um bind restrito a loopback. Consulte [Web Services e port binding](https://render.com/docs/web-services#port-binding).

Mantenha Auto-Deploy desligado para que o workflow controle a publicação após os testes. Enviar `commitId` pela API não desliga os auto-deploys por si só, conforme [Trigger deploy](https://api-docs.render.com/reference/create-deploy).

## 3. Configurar as variáveis da API no Render

| Variável | Valor / finalidade |
|---|---|
| `MONGODB_URI` | Connection string Atlas com usuário e banco próprios do ambiente |
| `JWT_SECRET` | Segredo aleatório de pelo menos 32 bytes, diferente por ambiente |
| `SEED_ENABLED` | `false` nos serviços públicos |
| `SEED_PASSWORD` | Sem valor quando o seed está desligado |
| `GEMINI_API_KEY` | Opcional; sem chave, recursos de IA retornam indisponibilidade |
| `GEMINI_MODEL` | Modelo configurado para a integração, quando utilizada |

`MONGO_DATABASE` é uma variável do Compose local. No Render, o banco precisa estar na `MONGODB_URI`. Sem essa variável, a aplicação tenta conectar em `localhost:27017`, onde o Web Service não possui o MongoDB local.

O cadastro público cria `OPERADOR`. Perfis `GESTOR` e `LIDER` para demonstração remota precisam ser preparados por quem administra o banco; o cadastro não promove usuários. Contas seed são destinadas ao ambiente local.

Em cada serviço, registre a URL pública e o identificador `srv-...` para configurar o GitHub. A chave da API Render, usada pelo CI para pedir o deploy, fica no repository secret `RENDER_API_KEY` do GitHub; não precisa ser variável da aplicação.

Os valores padrão de `GEMINI_MODEL` divergem: Compose e `.env.example` usam `gemini-2.5-flash`, enquanto `application.yml` usa `gemini-3.6-flash` se a variável estiver ausente. Defina-a explicitamente quando utilizar IA. Os nomes são valores presentes no repositório, sem validação da disponibilidade do modelo no provedor.

## 4. Configurar GitHub Actions

Em **Settings > Secrets and variables > Actions**, cadastre o **repository secret** `RENDER_API_KEY`, com acesso aos serviços utilizados. Esse escopo corresponde ao relato do PDF, página 11. O workflow lê `secrets.RENDER_API_KEY`; um environment secret do mesmo nome pode sobrescrever o valor do repositório, mas a duplicação não é obrigatória.

Em **Settings > Environments**, crie `staging` e `production` e configure as **Variables**:

| Tipo | Nome | Staging | Produção |
|---|---|---|---|
| Variable | `RENDER_SERVICE_ID` | ID `srv-...` do staging | ID `srv-...` da produção |
| Variable | `RENDER_PUBLIC_URL` | `https://esg-devops-staging.onrender.com` | `https://esg-devops-production.onrender.com` |

`RENDER_PUBLIC_URL` recebe a URL base, sem `/swagger-ui/index.html` ou `/healthz`; o script acrescenta o caminho de saúde. `GITHUB_SHA` é fornecido automaticamente pelo Actions. Os IDs reais e a chave não estão nas capturas, portanto não foram preenchidos nesta documentação.

O deploy é solicitado pela API Render; os serviços são acessados pelas URLs HTTPS públicas. O [guia do GitHub](COMO_CONFIGURAR_GITHUB.md) detalha eventos, etapas e critérios de sucesso.

## 5. Fluxo de publicação

1. Abra um PR com destino `develop` ou `main`: o Actions compila, testa e constrói a imagem; não publica o PR.
2. Faça merge/push em `develop`: após `build-test`, o job `staging` publica o SHA dessa execução.
3. Valide staging e faça merge de `develop` para `main`: uma nova execução valida o código e publica produção.
4. Para executar manualmente, selecione `develop` ou `main` em **Actions > Run workflow**.

O script de deploy faz `POST /v1/services/{serviceId}/deploys` com `commitId`, aceita HTTP `201` ou `202`, obtém o ID do deploy e consulta seu status. Interrompe em falha ou se não atingir `live` em até 90 consultas, espaçadas por 15 segundos, além do tempo das requisições. O job tem limite de 35 minutos. Ao atingir `live`, verifica `/healthz` e exige o JSON com `status=UP` e `application=voaaguia`.

O Render recomenda verificações que incluam dependências críticas, como uma consulta ao banco, em seu [guia de healthchecks](https://render.com/docs/health-checks). Nesta API, a dependência é verificada com `ping` no MongoDB.

## 6. Verificar os ambientes

No PowerShell:

```powershell
Invoke-RestMethod https://esg-devops-staging.onrender.com/healthz
Invoke-RestMethod https://esg-devops-production.onrender.com/healthz
```

A resposta esperada de cada ambiente é:

```json
{"status":"UP","application":"voaaguia"}
```

Abra também o Swagger de [staging](https://esg-devops-staging.onrender.com/swagger-ui/index.html) e [produção](https://esg-devops-production.onrender.com/swagger-ui/index.html). Nos logs do Actions, confira `Deploy LIVE + HTTP health check OK` e compare o SHA da execução com o deploy no Render. Esses comandos servem para uma nova verificação; o PDF, páginas 8 e 9, contém logs com `live` e `Deploy LIVE + HTTP health check OK`. Os PNGs individuais mostram o Swagger.

## Diagnóstico

| Sintoma | Verificação |
|---|---|
| Script informa variável ausente | Confira Secret/Variables do environment selecionado e os nomes exatos |
| Render rejeita deploy | Confira API key, ID do serviço, acesso ao repositório e commit solicitado |
| API tenta `localhost:27017` no Render | Configure `MONGODB_URI` no serviço e faça novo deploy |
| Falha de autenticação MongoDB | Confira usuário, senha codificada, banco e permissões no Atlas |
| Timeout MongoDB | Confira lista de acesso IP do Atlas e endereços de saída do Render |
| `/healthz` falha | Verifique conexão MongoDB nos logs; Swagger carregado sozinho não garante banco saudável |
| JWT impede a inicialização | Configure segredo com pelo menos 32 bytes |
| IA retorna 503 | A chave não foi configurada; os demais recursos podem continuar disponíveis |

## Limitações da infraestrutura acadêmica

O PDF identifica Render Free nos dois ambientes. Esse plano suspende serviços após 15 minutos sem tráfego, possui inicialização sob demanda, sistema de arquivos efêmero e cotas de uso compartilhadas. Dois serviços podem disputar a cota do mesmo workspace. Veja [Render Free](https://render.com/docs/free).

O Atlas mantém dois bancos no mesmo cluster: o isolamento é lógico. A auditoria H2 em memória é perdida ao reiniciar. Esta arquitetura permite demonstrar CI/CD; capacidade, disponibilidade comercial e políticas privadas não estão atestadas pelos prints.

As capturas e a análise de sua cobertura estão em [EVIDENCIAS.md](EVIDENCIAS.md). As divergências estão em [REVISAO_DOCUMENTACAO.md](REVISAO_DOCUMENTACAO.md).
