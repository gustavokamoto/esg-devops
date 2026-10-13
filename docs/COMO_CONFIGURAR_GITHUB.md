# Configuração do GitHub Actions e deploy remoto

## Fluxo da atividade

- Pull request em `develop` ou `main`: build Java + testes reais com MongoDB + build da imagem Docker.
- Push em `develop`: build/test e deploy em staging.
- Push em `main`: build/test, deploy em staging e depois em produção.
- Aprovação manual antes de produção: pode ser habilitada nas regras do GitHub Environment `production`, de acordo com o plano/permissões do repositório.

## Pré-requisitos fora do GitHub

O servidor ou computador **persistente** usado para deploy precisa ter Docker Engine, `docker compose`, SSH e `curl`, e precisa estar acessível ao runner do GitHub (diretamente ou por rede adequadamente configurada). Um runner hospedado pelo GitHub é temporário: não use `docker compose up` apenas no runner como comprovação de um deploy persistente.

No servidor (Linux), crie duas pastas, com `.env` individual. Exemplos:

- `/opt/voaaguia/staging/.env`: `COMPOSE_PROJECT_NAME=voaaguia-staging`, `HOST_BIND_IP=127.0.0.1`, `HOST_PORT=8081`, `MONGO_DATABASE=voaaguia_staging`, um `JWT_SECRET` próprio; `SEED_ENABLED=true` somente para demo privada, com `SEED_PASSWORD` de 12 ou mais caracteres.
- `/opt/voaaguia/production/.env`: `COMPOSE_PROJECT_NAME=voaaguia-production`, `HOST_BIND_IP=127.0.0.1`, `HOST_PORT=8082`, `MONGO_DATABASE=voaaguia_production`, outro `JWT_SECRET` próprio e `SEED_ENABLED=false`.

Copie as demais variáveis de `.env.example`. O usuário SSH de deploy precisa ter permissão para executar `docker compose`, criar pastas e escrever nos diretórios escolhidos. Configure a chave pública SSH do deploy como autorizada no servidor. O servidor deve ter recursos suficientes para duas APIs Java e dois MongoDB.

## Configurar ambientes GitHub

Em `Settings > Environments`, crie `staging` e `production`. Para **cada** environment, cadastre:

| Tipo | Nome | O que informar |
|---|---|---|
| Secret | `DEPLOY_HOST` | IP ou domínio do servidor |
| Secret | `DEPLOY_USER` | Usuário SSH de deploy |
| Secret | `DEPLOY_SSH_KEY` | Chave privada SSH específica do deploy |
| Secret | `DEPLOY_KNOWN_HOSTS` | Linha confiável de `known_hosts` referente ao host (confirme fingerprint fora da conexão) |
| Variable | `DEPLOY_DIR` | Caminho remoto absoluto para aquele ambiente |

Para facilitar: pode ser o mesmo servidor com diretórios e portas diferentes ou servidores distintos. Mantenha as chaves privadas e JWT fora do repositório. Não exponha MongoDB à Internet. Em produção pública, usar HTTPS por proxy reverso é recomendável.

## Publicar no GitHub

Na raiz do projeto:

```bash
git init
git add .
git commit -m "DevOps: pipeline, Docker Compose e documentacao"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git
git push -u origin main
```

Para exercitar um deploy primeiro em staging, crie e envie a branch `develop`:

```bash
git checkout -b develop
git push -u origin develop
```

Abra o menu `Actions` do repositório e confira o resultado. Em `main`, o job `production` roda após o job `staging`, desde que tenha credenciais e ambiente configurados. As portas são vinculadas ao loopback do servidor por padrão; para visualizar de seu PC use encaminhamento SSH (`ssh -L 8081:127.0.0.1:8081 -L 8082:127.0.0.1:8082 usuario@IP_DO_SERVIDOR`).

**Falha esperada se ainda não houver servidor:** o job de deploy interrompe na checagem dos secrets ou no acesso SSH. Não declare deploy concluído apenas porque o arquivo YAML existe.
