#!/usr/bin/env bash
set -euo pipefail

for name in RENDER_API_KEY RENDER_SERVICE_ID RENDER_PUBLIC_URL GITHUB_SHA; do
  if [[ -z "${!name:-}" ]]; then
    echo "ERRO: configure $name no GitHub. Consulte docs/GUIA_RENDER_ATLAS.md" >&2
    exit 1
  fi
done

endpoint="https://api.render.com/v1/services/${RENDER_SERVICE_ID}/deploys"
response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

# Solicita EXATAMENTE o commit cujo build e testes passaram (nao o ultimo de outra branch).
echo "Solicitando deploy para commit ${GITHUB_SHA:0:12} no servico ${RENDER_SERVICE_ID}"
http_code=$(curl --silent --show-error --retry 3 --retry-delay 3   --output "$response_file" --write-out '%{http_code}'   --request POST "$endpoint"   --header "Authorization: Bearer ${RENDER_API_KEY}"   --header 'Content-Type: application/json'   --header 'Accept: application/json'   --data "{\"commitId\":\"${GITHUB_SHA}\"}")

if [[ "$http_code" != "201" && "$http_code" != "202" ]]; then
  echo "Render rejeitou deploy (HTTP ${http_code}). Confira ID de servico, API key e branch." >&2
  jq -c '{message,code}' "$response_file" 2>/dev/null || true
  exit 1
fi

deploy_id=$(jq -r '.id // .deploy.id // empty' "$response_file")
if [[ -z "$deploy_id" ]]; then
  echo 'Render aceitou requisicao mas nao retornou ID para confirmar conclusao. Verifique o painel.' >&2
  exit 1
fi

echo "Deploy criado: ${deploy_id}"
for attempt in $(seq 1 90); do
  sleep 15
  status=$(curl --fail-with-body --silent --show-error --retry 3 --retry-delay 2     --header "Authorization: Bearer ${RENDER_API_KEY}"     --header 'Accept: application/json'     "${endpoint}/${deploy_id}" | jq -r '.status // "unknown"')
  echo "Render deploy [${attempt}/90]: ${status}"
  case "$status" in
    live) break ;;
    build_failed|update_failed|pre_deploy_failed|canceled|deactivated)
      echo "ERRO: deploy falhou, status ${status}. Consulte os logs do Render." >&2
      exit 1;;
  esac
  if [[ "$attempt" -eq 90 ]]; then
    echo 'ERRO: tempo maximo para deploy excedido; verifique logs Render.' >&2
    exit 1
  fi
done

health_url="${RENDER_PUBLIC_URL%/}/healthz"
echo "Verificando saude da API/MongoDB em ${health_url}"
health_response=$(curl --fail-with-body --silent --show-error   --retry 8 --retry-all-errors --retry-delay 5 --connect-timeout 15 --max-time 50 "$health_url")
echo "$health_response" | jq -e '.status == "UP" and .application == "voaaguia"' >/dev/null
echo "Deploy LIVE + HTTP health check OK - ${GITHUB_SHA:0:12}"
