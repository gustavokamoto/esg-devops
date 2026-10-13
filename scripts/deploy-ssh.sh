#!/usr/bin/env bash
# GitHub Actions envia os arquivos a um servidor persistente com Docker instalado.
# O .env fica NO SERVIDOR, nunca no repositório nem nos artefatos enviados.
set -euo pipefail
ARCHIVE="${1:?Informe o arquivo tar.gz de deploy}"
: "${DEPLOY_HOST:?Configure DEPLOY_HOST no environment do GitHub}"
: "${DEPLOY_USER:?Configure DEPLOY_USER no environment do GitHub}"
: "${DEPLOY_DIR:?Configure a variavel DEPLOY_DIR no environment do GitHub}"
SSH=(ssh -i "$HOME/.ssh/voaaguia_deploy_key" -o BatchMode=yes -o StrictHostKeyChecking=yes)
SCP=(scp -i "$HOME/.ssh/voaaguia_deploy_key" -o BatchMode=yes -o StrictHostKeyChecking=yes)
REMOTE="${DEPLOY_USER}@${DEPLOY_HOST}"
# DEPLOY_DIR é uma variável administrada pelo dono do repositório (ex: /opt/voaaguia/staging).
# Somente valores com caminho simples são aceitos.
if [[ ! "$DEPLOY_DIR" =~ ^(/[a-zA-Z0-9_./-]+)$ ]]; then
  echo "DEPLOY_DIR invalido (use caminho absoluto sem espacos)" >&2
  exit 2
fi
"${SSH[@]}" "$REMOTE" "mkdir -p -- '$DEPLOY_DIR'"
"${SCP[@]}" "$ARCHIVE" "$REMOTE:$DEPLOY_DIR/deploy.tar.gz"
"${SSH[@]}" "$REMOTE" "cd '$DEPLOY_DIR' && test -f .env && tar -xzf deploy.tar.gz && docker compose up -d --build --remove-orphans && docker compose ps"
# Verificação do endpoint Swagger usando a porta publicada declarada no .env remoto.
"${SSH[@]}" "$REMOTE" "cd '$DEPLOY_DIR' && HOST_PORT=\$(sed -n 's/^HOST_PORT=//p' .env | tail -n 1); test -n \"\$HOST_PORT\" && curl --retry 20 --retry-connrefused --retry-delay 3 --fail --silent --show-error \"http://127.0.0.1:\$HOST_PORT/v3/api-docs\" >/dev/null"
echo "Deploy concluido e /v3/api-docs respondeu com sucesso."
