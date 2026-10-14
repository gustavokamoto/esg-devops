# Auditoria e padronização da documentação — Voa Águia

Atividade: **Navegando pelo Mundo DevOps**, FIAP. Referência acadêmica: [relatório técnico PDF](Voa_Aguia_Relatorio_Tecnico_DevOps_Final.pdf), de 13 de outubro de 2026, com 12 páginas. Fonte de verdade técnica: código e configurações atuais do repositório.

## A. Arquivos revisados e alterações

| Caminho | Resultado |
|---|---|
| [README.md](../README.md) | Reorganizado nas 21 seções solicitadas: identidade, integrantes, ESG, versões, arquitetura, execução, testes, Docker, pipeline, nuvem, evidências, desafios e checklist |
| [COMO_CONFIGURAR_GITHUB.md](COMO_CONFIGURAR_GITHUB.md) | Repository secret, variables dos environments, etapas reais de CI/CD, condições de branches, critérios de falha e limitações da promoção |
| [GUIA_RENDER_ATLAS.md](GUIA_RENDER_ATLAS.md) | Nomes dos bancos confirmados no PDF, configuração Render/Atlas, escopos de variáveis, limitações do plano gratuito e divergência Gemini |
| [PASSO_A_PASSO.md](PASSO_A_PASSO.md) | Roteiro coerente com PDF e pipeline, limpeza do banco temporário de testes, referências às evidências existentes e conferência do pacote |
| [EVIDENCIAS.md](EVIDENCIAS.md) | Catálogo ampliado com figuras incorporadas ao PDF, saúde e bancos comprovados, histórico de testes locais separado do CI e ocorrências atribuídas ao relatório |
| [evidencias/LEIA-ME.md](evidencias/LEIA-ME.md) | Índice dos cinco PNGs e localização das evidências adicionais no PDF |
| [REVISAO_DOCUMENTACAO.md](REVISAO_DOCUMENTACAO.md) | Relatório de alinhamento, validação, limitações técnicas e pendências |

O `.env.example` foi auditado e contém placeholders e valores públicos de exemplo, sem credenciais reais. Foi preservado. O PDF e os cinco PNGs foram mantidos como fontes originais. As figuras presentes somente no PDF continuam referenciadas nele.

### Escopo preservado

Esta etapa altera apenas documentação Markdown. Código Java, testes, Dockerfile, Compose, workflow, scripts, `pom.xml`, `application.yml` e `.env.example` permanecem como estavam no início desta tarefa. Alterações não commitadas da revisão anterior nesses arquivos foram preservadas, sem serem tratadas como novas alterações desta padronização.

Não foram executados deploys, commits, pushes ou edições em contas GitHub/Render/Atlas. A leitura do PDF usou um container temporário de ferramentas; isso não iniciou a API nem modificou o PDF. Renderizações de inspeção ficam em `target/`, fora do Git e da entrega.

## B. Inconsistências corrigidas

| Informação anterior | Correção documental | Base |
|---|---|---|
| README sem integrantes e relação ESG explícita | Quatro nomes completos e relação limitada às funcionalidades implementadas | PDF p. 1–2 e serviços da API |
| PDF ausente da documentação de entrega | Link e mapa de páginas/figuras do relatório disponível | Arquivo PDF em `docs/` |
| Detalhes de jobs, saúde e Atlas tratados como não anexados | Capturas reconhecidas como incorporadas ao PDF | Figuras 3, 5, 7 e 9 |
| Bancos remotos tratados apenas como nomes sugeridos | `voaaguia_staging` e `voaaguia_production` identificados como registrados | Data Explorer, PDF p. 10 |
| Chave Render exigida em cada environment | Repository secret documentado; override por environment explicado como opção suportada | PDF p. 11 e referência `secrets.RENDER_API_KEY` no YAML |
| Geração de PDF indicada como pendência | PDF presente marcado como concluído | Relatório de 12 páginas com capturas |
| Referências remanescentes ao procedimento remoto antigo | Instruções concentradas na API Render e nas URLs HTTPS | Workflow e script atuais |
| Promoção para produção descrita sem distinguir regra de processo | PR `develop` → `main` descrito como processo; `needs: build-test` descrito como condição real | Condições dos jobs no YAML |
| Nove testes locais apresentados como validação da revisão atual | Resultado atribuído à revisão anterior e aos relatórios existentes | `target/surefire-reports`, sem nova execução nesta etapa |
| Checklist em lista com pendências genéricas | Tabela com os oito itens FIAP e respectivas fontes | Requisitos fornecidos e PDF p. 12 |

### Divergência com o checklist do PDF

A página 12 afirma que o ZIP foi montado e marca esse item como concluído. Nenhum ZIP está disponível na raiz ou nas demais pastas de entrega inspecionadas deste repositório. Assim, o README registra **pendente de conferência**, sem alterar o relatório de referência. A afirmação histórica do PDF não permite auditar o conteúdo ou a versão do pacote ausente.

As evidências comprovam os commits capturados naquele momento. As mudanças locais posteriores, inclusive esta documentação, não devem ser declaradas implantadas no Render sem uma nova publicação autorizada e verificada.

## C. Validação de alinhamento

| Requisito / tema | Referência no PDF | Conferência no repositório | Diagnóstico |
|---|---|---|---|
| Nome e integrantes | P. 1 | README seção 2 | Alinhado com os quatro nomes fornecidos |
| Propósito e ESG | P. 2 | Serviços de estratégias, ideias, projetos, dashboard e permissões | Alinhado, sem alegar indicadores ESG específicos inexistentes |
| Java, Spring Boot e Maven | P. 3–4 | Java 17, Boot 3.5.6, Maven 3.9.9 | Alinhado; detalhes adicionais de dependências no README |
| Arquitetura local | P. 3–4 e 6 | Compose: `api`, `mongo`, rede e volume | Alinhado |
| H2 e persistência | P. 3 e 11 | Datasource H2 em memória; MongoDB para negócio | Limitação registrada |
| Política de branches | P. 5 | PR valida; `develop` publica staging; `main` publica produção | Alinhado; aprovação de staging não é condição obrigatória do YAML |
| Build, testes e imagem | P. 7, figura 3 | Job `build-test`, Maven verify, MongoDB e Docker build | Comprovado por captura; contagem remota não informada |
| Deploy staging | P. 8, figura 5 | Job `staging`, SHA específico, espera `live`, saúde | Comprovado nas evidências |
| Deploy produção | P. 9, figura 7 | Job `production`, SHA específico, espera `live`, saúde | Comprovado nas evidências |
| Swagger | P. 6, 8–9 | URLs e arquivos PNG existentes | Comprovado no momento da coleta |
| Atlas separado | P. 10, figura 9 | Banco selecionado pela URI de cada serviço | Dois bancos comprovados; configurações privadas não exibidas |
| Repository secret | P. 11 | `secrets.RENDER_API_KEY` | Compatível; escopo real no painel não foi consultado |
| PDF técnico | Relatório completo | Arquivo existente em `docs/` | Concluído |
| ZIP | P. 12 declara concluído | Arquivo não localizado para inspeção | Conferência pendente |

O PDF registra configuração JWT independente entre serviços; nenhum valor de segredo foi exposto. A existência de dois bancos no mesmo cluster comprova separação lógica, sem atestar isolamento físico, contas distintas ou políticas de acesso.

### Ocorrências históricas e grau de confirmação

A página 11 relata ausência de `RENDER_API_KEY`, URI MongoDB sem banco e HTTP 401 no healthcheck. A documentação apresenta causa e solução como relato do PDF. O código atual confirma o mapeamento da chave, a configuração de URI e `/healthz` em `permitAll`. As capturas de deploy mostram sucesso posterior. Os logs das falhas originais não foram fornecidos; não foi reconstruída uma cronologia além do que as fontes permitem.

### Verificações documentais concluídas

- Sete documentos Markdown revisados, com as 21 seções do README presentes e numeradas em sequência.
- 82 referências locais conferidas, incluindo imagens, PDF, arquivos técnicos e uma âncora Markdown; nenhum destino ausente.
- 16 blocos de exemplo PowerShell analisados pelo parser, sem executar os comandos; sintaxe válida.
- Script de deployment conferido com `bash -n`, sem executar suas chamadas de publicação; sintaxe válida.
- `git diff --check` sem problemas de espaços em branco.
- Hashes SHA-256 de 44 arquivos de referência, incluindo o PDF e os arquivos técnicos, iguais aos registrados no início desta tarefa.
- Busca recursiva de ZIP sem resultado; ausência do pacote confirmada nesta pasta.
- `.env.example` inspecionado sem credenciais reais; documentos sem padrões de chave privada, token GitHub/Render ou JWT real. Os exemplos de URI usam placeholders. A inspeção visual das páginas do PDF não identificou valores de senha ou chave nas capturas.

Os links externos técnicos usados para limitações Render, deploy e comportamento de secrets/concorrência GitHub foram conferidos em documentação oficial. As URLs da aplicação foram comparadas com as capturas; não houve nova consulta de disponibilidade dos serviços. A sintaxe dos comandos foi conferida separadamente de sua execução: não representa um novo teste de funcionamento.

## D. Limitações técnicas e pendências

### Pontos técnicos identificados, sem alteração do sistema

| Ponto | Evidência | Implicação / orientação |
|---|---|---|
| Modelos Gemini padrão divergentes | Compose/`.env.example`: `gemini-2.5-flash`; `application.yml`: `gemini-3.6-flash` | Definir `GEMINI_MODEL` explicitamente; disponibilidade externa não validada |
| Auditoria sem persistência | H2 `jdbc:h2:mem:voaaguia_audit` | Eventos de login/cadastro se perdem após reinício |
| Produção não depende de staging | `production.needs: build-test` | Fluxo de promoção é procedimento; enforcement depende de políticas externas |
| API sem healthcheck Docker no Compose | Healthcheck declarado somente em `mongo` | Consultar `/healthz` para validar API/banco, além de `docker compose ps` |
| Exclusão parcial no contexto Docker | `.dockerignore` exclui `.env`, mas não todas as variantes `.env.*` | Não incluir arquivos privados alternativos no contexto; o Dockerfile atual copia somente `pom.xml` e `src` |
| Contagem de testes distinta das evidências históricas | Relatórios locais: 8 integração + 1 auditoria; prints CI sem contagem | Não atribuir os nove testes ao pipeline remoto fotografado |
| API Render sem timeout por transferência no POST/polling | `curl` inicial e de status sem `--max-time`; job limitado a 35 minutos | Requisição bloqueada pode consumir o timeout do job; registro para futura melhoria, sem mudança nesta tarefa |

O `.env.example` mantém seus padrões para não modificar configuração de funcionamento. Nenhuma chave ou senha real foi inserida nele ou nos documentos. Os únicos exemplos de URI autenticada usam placeholders explícitos.

### Pendência necessária para a entrega

Disponibilizar ou montar o **ZIP final**, conferir a estrutura e verificar que não contém `.env` real ou variantes privadas, credenciais, `.git`, `target` ou renderizações temporárias. O pacote deve incluir Wrapper, código, Dockerfile, Compose, workflow, script, README, documentação, PDF e cinco PNGs. Confira sua correspondência com a versão de código pretendida.

### Complementos opcionais de rastreabilidade

- Artefatos Maven da execução CI fotografada, se for preciso comprovar sua contagem exata de testes.
- Capturas das permissões de usuários Atlas e regras de rede, com valores sensíveis ocultos, se exigidas pelo avaliador.
- Logs originais das três falhas relatadas, se for preciso auditar causas e datas além do relato do PDF.

Esses complementos não são tratados como ausência das evidências de deploy ou de banco, pois elas já constam no PDF.

## E. Resultado final

A documentação Markdown está organizada conforme os requisitos fornecidos, alinhada ao comportamento técnico atual e vinculada às evidências do PDF. A conferência foi documental: estrutura, configurações, imagens, páginas, referências, comandos e histórico existente. Não se afirma disponibilidade contínua dos serviços ou uma nova implantação.

A documentação pode compor a entrega acadêmica. O pacote completo ainda depende da conferência do ZIP e de sua versão; esse é o único item obrigatório sem artefato verificável no repositório inspecionado. O checklist do README registra essa ressalva explicitamente em relação à página 12 do PDF.
