# Evidências de execução — preencher somente após testes reais

Nenhuma imagem ou print nesta pasta comprova execução até que seja capturado por você.

Capture estes materiais para adicionar ao PDF/PPT final:

1. `01-compose-local.png`: terminal com `docker compose ps` exibindo `api` e `mongo` em execução.
2. `02-swagger-local.png`: `http://localhost:8080/swagger-ui/index.html` (ou HOST_PORT local).
3. `03-actions-build-test.png`: workflow no GitHub Actions, job "Build e testes" verde.
4. `04-actions-staging.png`: workflow exibindo job "Deploy automatico - staging" verde.
5. `05-staging.png`: navegador em `http://localhost:8081/swagger-ui/index.html` (com túnel SSH aberto do seu computador).
6. `06-actions-production.png`: workflow exibindo job "Deploy automatico - producao" verde.
7. `07-production.png`: navegador em `http://localhost:8082/swagger-ui/index.html` (com túnel SSH aberto do seu computador).
8. `08-compose-ambientes.png`: `docker compose ps` em cada ambiente.

Para a apresentação, explique os desafios reais encontrados durante a execução e como foram solucionados.

## Observações

- URLs e portas são EXEMPLOS, ajuste conforme suas variáveis.
- Sem servidor configurado, a GitHub Action passa no build/testes mas NÃO consegue completar deploy.
- Os relatórios em `target/surefire-reports` presentes no ZIP original foram omitidos de propósito: são resultados antigos, não evidência nova do pipeline.
