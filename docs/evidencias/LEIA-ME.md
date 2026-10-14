# Capturas de execução — Voa Águia

Esta pasta contém cinco PNGs originais. O [PDF técnico](../Voa_Aguia_Relatorio_Tecnico_DevOps_Final.pdf) acrescenta capturas incorporadas dos jobs e dos bancos Atlas:

| Arquivo | Conteúdo |
|---|---|
| [containerLocal.png](containerLocal.png) | `docker ps` com API e MongoDB locais ativos |
| [swaggerLocal.png](swaggerLocal.png) | Swagger em `localhost:8080` |
| [actionsSuccess.png](actionsSuccess.png) | Quatro execuções verdes do workflow Render e Atlas |
| [swaggerStaging.png](swaggerStaging.png) | Swagger em `esg-devops-staging.onrender.com` |
| [swaggerProducao.png](swaggerProducao.png) | Swagger em `esg-devops-production.onrender.com` |

Os nomes dos arquivos foram preservados e as imagens estão incorporadas no [README](../../README.md) e no [relatório de evidências](../EVIDENCIAS.md), com legendas e limites do que cada captura demonstra.

No PDF, a página 7 mostra o job de build/testes/imagem, as páginas 8–9 mostram deploys com `live` e healthcheck aprovado, e a página 10 mostra `voaaguia_staging` e `voaaguia_production`. Essas imagens permanecem referenciadas no relatório, sem arquivos substitutos nesta pasta.

Para complementar a rastreabilidade, preserve os artefatos de testes e confirme os commits do pacote. Oculte credenciais, tokens e a URI autenticada do Atlas em qualquer captura adicional. A identificação dos integrantes e o checklist estão no README; as pendências estão em [REVISAO_DOCUMENTACAO.md](../REVISAO_DOCUMENTACAO.md).
