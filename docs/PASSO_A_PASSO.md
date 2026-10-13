# Passo a passo — Voa Águia (Windows + GitHub Actions + servidor Linux)

Este tutorial descreve o caminho completo para comprovar os requisitos do desafio sem inventar execuções. **A pasta de projeto enviada contém apenas o backend**; se o seu trabalho acadêmico exige também o aplicativo Android/frontend de desafios anteriores, inclua-o no arquivo final.

## 1. Instale o necessário no seu PC Windows

- Docker Desktop para Windows: https://docs.docker.com/desktop/setup/install/windows-install/ (inicie o aplicativo e mantenha o motor Docker rodando).
- Git para Windows: https://git-scm.com/downloads/win.
- Conta no GitHub: https://github.com/.
- Java 17 (opcional para teste local; no GitHub Actions já é provisionado): https://adoptium.net/.

Verifique no PowerShell:

```powershell
docker --version
docker compose version
git --version
```

## 2. Coloque o projeto em uma pasta no seu PC

Extraia o pacote `VoaAguia-DevOps.zip`. Abra PowerShell na pasta **VoaAguia-DevOps**, que deve conter `pom.xml`, `src`, `Dockerfile`, `docker-compose.yml`, `.github`, `docs` e `.env.example`. No Windows Explorer, habilite **Exibir > Itens ocultos** para enxergar pastas com ponto.

## 3. Configure segredos locais

```powershell
Copy-Item .env.example .env
notepad .env
```

No `.env`, substitua `JWT_SECRET` por um segredo único de pelo menos 32 bytes. Para gerar um exemplo aleatório no PowerShell (sem Python):

```powershell
$bytes = New-Object byte[] 48
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$rng.Dispose()
[Convert]::ToBase64String($bytes)
```

Cole a saída na linha `JWT_SECRET=` do `.env`. Para contas de demonstração, defina `SEED_ENABLED=true` e informe uma senha aleatória de 12+ caracteres em `SEED_PASSWORD=`. Se não precisar desses usuários, deixe `SEED_ENABLED=false`. `GEMINI_API_KEY` é opcional: sem ela, apenas as funções de IA não respondem normalmente.

**Nunca inclua o arquivo `.env` no GitHub ou no ZIP da entrega.**

## 4. Suba o backend e MongoDB via Docker

Execute na raiz do projeto:

```powershell
docker compose config
docker compose up -d --build
docker compose ps
docker compose logs --tail=100 api
```

Se aparecerem os dois serviços, abra no navegador:

- http://localhost:8080/swagger-ui/index.html
- http://localhost:8080/v3/api-docs

Tire os prints do `docker compose ps` e da página Swagger. Se a porta 8080 estiver ocupada, mude `HOST_PORT=18080` no `.env`, reexecute `docker compose up -d --build`, e use `http://localhost:18080/`.

**Para parar sem apagar o banco**: `docker compose down`. Não rode `docker compose down -v` se quiser manter os dados.

## 5. Faça os testes

O GitHub Actions executará a suíte no CI. Se quiser validar no PC e tiver Java 17, inicie um MongoDB para os testes (a instância do Compose não publica sua porta 27017):

```powershell
docker run -d --name voaaguia-mongo-teste -p 27017:27017 mongo:7.0
.\mvnw.cmd clean verify
docker stop voaaguia-mongo-teste
docker rm voaaguia-mongo-teste
```

Aguarde o MongoDB ficar pronto antes do Maven (`docker logs voaaguia-mongo-teste`). Se já houver MongoDB na porta 27017, não inicie outro container. O esperado é `BUILD SUCCESS`; caso contrário, anote o erro e corrija-o antes de seguir.

## 6. Prepare um servidor Linux para os deploys

**É necessário um computador ou VPS Linux persistente**, com acesso por SSH a partir do GitHub Actions e com Docker Engine/Compose instalados. O GitHub-hosted runner não é servidor permanente de staging/produção. Instruções oficiais do Docker Engine no Ubuntu: https://docs.docker.com/engine/install/ubuntu/.

Acesse seu servidor (substitua com seu login/IP):

```bash
ssh USUARIO@IP_DO_SERVIDOR
```

Após instalar Docker Engine e Docker Compose plugin, confira `docker --version` e `docker compose version`. Garanta que o **usuário SSH que fará o deploy** tenha permissão para executar `docker compose`. Adicionar usuário ao grupo `docker` concede privilégios equivalentes a administrador: use conta restrita e proteja sua chave.

No Linux, crie as pastas (supondo que o próprio usuário acessado fará o deploy):

```bash
sudo mkdir -p /opt/voaaguia/staging /opt/voaaguia/production
sudo chown -R "$USER:$USER" /opt/voaaguia
```

Crie arquivos **separados** de variáveis, diretamente no servidor:

`/opt/voaaguia/staging/.env`:

```dotenv
COMPOSE_PROJECT_NAME=voaaguia-staging
HOST_BIND_IP=127.0.0.1
HOST_PORT=8081
MONGO_DATABASE=voaaguia_staging
JWT_SECRET=COLE_UM_SEGREDO_ALEATORIO_DE_NO_MINIMO_32_BYTES
SEED_ENABLED=true
SEED_PASSWORD=ESCOLHA_UMA_SENHA_FORTE_COM_PELO_MENOS_12_CARACTERES
GEMINI_API_KEY=
GEMINI_MODEL=gemini-2.5-flash
```

`/opt/voaaguia/production/.env`:

```dotenv
COMPOSE_PROJECT_NAME=voaaguia-production
HOST_BIND_IP=127.0.0.1
HOST_PORT=8082
MONGO_DATABASE=voaaguia_production
JWT_SECRET=COLE_OUTRO_SEGREDO_ALEATORIO_DE_NO_MINIMO_32_BYTES
SEED_ENABLED=false
SEED_PASSWORD=
GEMINI_API_KEY=
GEMINI_MODEL=gemini-2.5-flash
```

Gere dois segredos distintos, por exemplo no servidor com `openssl rand -base64 48`. Cole os valores nos arquivos usando `nano /opt/voaaguia/staging/.env` e `nano /opt/voaaguia/production/.env`. Restringa o acesso: `chmod 600 /opt/voaaguia/{staging,production}/.env`.

As portas 8081/8082 ficam **fechadas para acesso externo** por padrão, o que é intencional. Para apresentar os sites, use o túnel SSH indicado no passo 10.

## 7. Crie uma chave SSH de deploy dedicada

No PowerShell do seu PC, crie uma chave dedicada (um procedimento por servidor/conta, não reuso de chave pessoal):

```powershell
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\voaaguia_deploy"
```

Quando o comando perguntar por uma senha (*passphrase*) para a chave, pressione Enter para deixá-la sem senha, pois este exemplo de workflow não tem agente SSH para desbloqueá-la. Use a chave apenas para este deploy, proteja o arquivo privado e limite o acesso da conta remota.

Cadastre o conteúdo do arquivo `voaaguia_deploy.pub` no `~/.ssh/authorized_keys` do **usuário de deploy** no servidor. Você pode fazer isso copiando a linha pública e editando o arquivo no Linux, configurando permissões `700` para `~/.ssh` e `600` para `~/.ssh/authorized_keys`.

Teste:

```powershell
ssh -i "$env:USERPROFILE\.ssh\voaaguia_deploy" USUARIO@IP_DO_SERVIDOR
```

Em um ambiente com `ssh-keyscan` (por exemplo Git Bash/WSL), obtenha a linha de `known_hosts` usando `ssh-keyscan -H IP_DO_SERVIDOR`. **Antes de confiar nessa linha, confirme a fingerprint do servidor por meio de seu painel/provedor ou outro canal seguro**. Copie o conteúdo resultante (sem editar) para o secret `DEPLOY_KNOWN_HOSTS`.

## 8. Crie o repositório e configure GitHub Actions

No GitHub, crie um repositório chamado `voaaguia-devops`, preferencialmente sem README inicial, pois o projeto já tem um. Se usar conta GitHub Free e precisar de `Environment secrets`, use repositório público **somente depois de revisar se o código não possui senhas/dados privados**. Recursos de environment em repositório privado exigem plano GitHub compatível: https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments.

Vá em `Settings > Environments`, crie exatamente dois environments: `staging` e `production`. Em **cada** um, configure os quatro **Secrets**:

- `DEPLOY_HOST`: IP ou DNS do servidor.
- `DEPLOY_USER`: nome do usuário SSH no servidor.
- `DEPLOY_SSH_KEY`: **conteúdo completo da chave PRIVADA** `voaaguia_deploy`, incluindo `BEGIN/END OPENSSH PRIVATE KEY`. Não a coloque no Git nem a envie em mensagens.
- `DEPLOY_KNOWN_HOSTS`: linha confiável do `known_hosts` obtida acima.

Em **cada** environment, adicione uma **Variable** chamada `DEPLOY_DIR`:

- staging: `/opt/voaaguia/staging`
- production: `/opt/voaaguia/production`

Se disponível no seu plano, configure `production` para exigir aprovação antes de executar, como boa prática adicional. Se não houver o servidor e essas credenciais, o pipeline poderá fazer build/testes, mas o deploy **não passará**.

## 9. Suba o código e dispare as execuções

Abra PowerShell na raiz do projeto:

```powershell
git init
git add .
git commit -m "DevOps: Voa Aguia CI/CD"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/voaaguia-devops.git
git push -u origin main
```

**Importante:** execute os passos 6 a 8 **antes desse push** se deseja que o primeiro pipeline em `main` já implante em ambos os ambientes.

Crie `develop` para demonstrar o fluxo de staging:

```powershell
git switch -c develop
git push -u origin develop
```

Na guia `Actions` do GitHub, abra `Voa Aguia - CI/CD`. Em `develop`, confira `Build e testes` e `Deploy automatico - staging`. Em `main`, confirme `Build e testes`, `staging` e depois `production`. Para demonstrar alteração posterior, faça um pequeno ajuste no README em `develop`, commit e push; depois mescle para `main`:

```powershell
git switch main
git merge develop
git push origin main
```

Não precisa alterar o código apenas para gerar prints se o workflow inicial já rodou corretamente; use os jobs verdes reais.

## 10. Confira staging e produção

Do seu computador, abra um segundo PowerShell com encaminhamento SSH, deixando a sessão aberta:

```powershell
ssh -i "$env:USERPROFILE\.ssh\voaaguia_deploy" -L 8081:127.0.0.1:8081 -L 8082:127.0.0.1:8082 USUARIO@IP_DO_SERVIDOR
```

No navegador do computador, acesse:

- **Staging:** http://localhost:8081/swagger-ui/index.html
- **Produção:** http://localhost:8082/swagger-ui/index.html

Essas URLs representam **ambientes remotos distintos no servidor**, acessados pelo túnel SSH — não são containers locais, apesar do `localhost` no navegador. O acesso de servidor a cada ambiente também pode ser verificado por SSH:

```bash
cd /opt/voaaguia/staging && docker compose ps
cd /opt/voaaguia/production && docker compose ps
```

Se a porta 8081 ou 8082 já estiver ocupada no seu PC, use outras portas **do lado esquerdo** do túnel, por exemplo `-L 18081:127.0.0.1:8081`, e abra `http://localhost:18081/`.

## 11. Capture as evidências exigidas

Faça **prints reais** da execução:

1. Terminal local com `docker compose ps` e API/MongoDB ativos.
2. Swagger local.
3. GitHub Actions: build e testes aprovados.
4. GitHub Actions: deploy staging aprovado.
5. Swagger staging no navegador com a URL visível.
6. GitHub Actions: deploy produção aprovado.
7. Swagger produção no navegador com a URL visível.
8. `docker compose ps` de staging e produção no servidor.

Adicione os prints em `docs/evidencias/`; no PDF/PPT, mostre pipeline (ferramenta, etapas e lógica), arquitetura `API ↔ MongoDB`, Dockerfile, Compose, comandos e imagem, capturas e **desafios reais + soluções**. Na primeira página, coloque **Voa Águia** e nome(s) dos integrante(s), não “Cidades ESG Inteligentes”.

## 12. Faça o pacote de entrega

No `README.md`, atualize a seção **Prints do funcionamento** com nomes/links das capturas reais e marque o checklist final somente após verificar cada item. Atualize a documentação PDF/PPT com as imagens, nomes, etapas e problemas reais da sua execução.

Compacte a pasta contendo `src`, `pom.xml`, `Dockerfile`, `docker-compose.yml`, `.env.example`, `.github/workflows`, scripts, `README.md` e documentação. **Não inclua** `.env`, chaves privadas, `target`, senhas nem dados reais. Abra o ZIP para conferir o conteúdo antes de enviar à plataforma; após o prazo ou correção, pode não ser possível substituir a entrega.

## Problemas mais comuns

| Sintoma | Como checar/corrigir |
|---|---|
| `docker` não reconhecido | Instale e inicie Docker Desktop; reabra PowerShell |
| Porta 8080 ocupada | Troque `HOST_PORT` no `.env` para 18080 |
| API reiniciando | Veja `docker compose logs --tail=100 api`; confira `JWT_SECRET` (32+ bytes) e `SEED_PASSWORD` (12+ se seed ativo) |
| Build/teste falha no CI | Abra job `Build e testes` e consulte logs; MongoDB deve estar healthy |
| Deploy falha antes do SSH | Confira `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_KNOWN_HOSTS`, `DEPLOY_DIR` no environment correto |
| `Permission denied` no SSH | Chave privada do secret deve corresponder à chave pública em `authorized_keys`; confira usuário/permissões |
| `docker: permission denied` no servidor | Usuário de deploy precisa de permissão para usar Docker; consulte documentação Docker para pós-instalação |
| Swagger remoto não abre | Veja jobs de deploy e `docker compose ps`; abra o túnel SSH; confirme `HOST_PORT` e variáveis diferentes |
| `GEMINI_API_KEY` ausente | A API principal funciona, mas endpoints de IA podem responder 503 |
