# /dev-team-start

Inicia o time de desenvolvimento a partir de um PRD.

## Uso

```
/dev-team-start
/dev-team-start docs/prd.md
```

Se nenhum caminho for passado, solicite que o usuario cole o PRD diretamente no chat.

## Execucao — siga esta sequencia exatamente (10 passos)

O fluxo agora passa por **wireframes aprovados pelo usuario** e **contratos por feature** ANTES de criar tarefas. Nao crie tarefas no `board/todo/` ate o usuario aprovar os wireframes.

---

### PASSO 1 — Criar estrutura do board e docs

Verifique se `board/` existe. Se nao existir, crie a estrutura:

```bash
mkdir -p board/{todo,in_progress,done,verified,blocked}
mkdir -p docs/wireframes docs/contracts
mkdir -p tests/{unit,integration,e2e/{specs,screenshots}}
```

Crie `docs/DECISIONS.md` se nao existir:
```markdown
# Decisoes Tecnicas

> Todos os agentes devem ler antes de implementar.
> Formato de cada decisao: DEC-{AGENT}-{N} com contexto, decisao, justificativa e alternativas descartadas.

## Stack

| Camada | Tecnologia | Versao | Decidido em | Por |
|---|---|---|---|---|
| Backend | [a definir] | - | - | - |
| Frontend | [a definir] | - | - | - |
| Banco de dados | [a definir] | - | - | - |
| Testes unitarios | [a definir] | - | - | - |
| Testes integracao | [a definir] | - | - | - |
| Testes E2E | Playwright | latest | {DATA_ATUAL} | tech-lead-agent |

## Decisoes
```

Crie `docs/PROGRESS.md` se nao existir:
```markdown
# Progress Log

> Timeline do projeto. Uma linha por evento.

- {DATA_ATUAL} | PROJETO | inicio | orchestrator | Projeto iniciado, aguardando wireframes do PO
```

Se `board/` ja existir (projeto retomado), leia o estado atual e pule para o PASSO 2.

---

### PASSO 2 — PO Agent cria wireframes

```
Agent(subagent_type="po-agent", prompt="
FASE 1 — Wireframes. NAO crie tarefas ainda.

Leia o PRD abaixo e siga seu protocolo de wireframes:
1. Identifique todas as telas funcionais (use slugs kebab-case como nome)
2. Para cada tela, crie docs/wireframes/{nome}.html em HTML puro (SEM CSS/JS)
3. Use o template do seu agent file: cabecalho de comentario com estados, botoes nomeados, inputs tipados
4. Crie docs/wireframes/index.html listando todas as telas
5. Reporte: telas criadas, cobertura do PRD, funcionalidades sem UI (que viram contratos so de API)

PRD:
{CONTEUDO_COMPLETO_DO_PRD}
")
```

---

### PASSO 3 — Tech Lead revisa wireframes

```
Agent(subagent_type="tech-lead-agent", prompt="
Revisao tecnica dos wireframes em docs/wireframes/.

Siga a secao 'Revisao de wireframes' do seu agent file:
1. Liste e leia todos os wireframes
2. Valide cabecalho de estados, nomes de acoes, tipos de input, consistencia de fluxo
3. Cruze com o PRD: toda funcionalidade com UI esta coberta?
4. Decida: APROVADO TECNICAMENTE ou REJEITADO com lista de problemas concretos
5. Registre em PROGRESS.md
6. Reporte ao orquestrador

PRD:
{CONTEUDO_COMPLETO_DO_PRD}
")
```

Se o Tech Lead rejeitar: invoque o `po-agent` novamente com o feedback (ele segue 'Protocolo de revisao apos feedback'). Limite 2 iteracoes nesta fase.

---

### PASSO 4 — Gate de aprovacao do usuario

**PARE a execucao automatica.** Mostre ao usuario:

```
Wireframes prontos para revisao:

  Indice: docs/wireframes/index.html

  Telas:
    - login (docs/wireframes/login.html)
    - cadastro-cliente (docs/wireframes/cadastro-cliente.html)
    - {...}

Abra o indice no navegador e revise.

Aprovar? Responda:
  - "s" ou "sim" para aprovar e prosseguir
  - Qualquer outro texto sera tratado como feedback e enviado ao PO para ajustes
```

Aguarde a resposta do usuario.

- Se a resposta for `s`/`sim`: prossiga ao PASSO 5.
- Caso contrario: invoque o `po-agent` com o feedback do usuario e volte ao PASSO 3 (Tech Lead revisa de novo). **Limite total: 3 ciclos do gate.** Se exceder, reporte ao usuario que ha algo estrutural a resolver antes de continuar.

---

### PASSO 5 — Tech Lead define a stack

```
Agent(subagent_type="tech-lead-agent", prompt="
Setup inicial de stack: os wireframes foram aprovados pelo usuario e estao em docs/wireframes/.

Siga seu protocolo de setup inicial:
1. Liste e leia os wireframes para entender as necessidades tecnicas (formularios, listagens, auth, uploads, etc.)
2. Defina a stack tecnica completa (linguagem, framework, versoes, padroes)
3. OBRIGATORIO: inclua Playwright como ferramenta de E2E (fonte de verdade do QA)
4. Registre TODAS as decisoes em docs/DECISIONS.md com justificativa (formato DEC-TL-XXX)
5. Atualize a tabela Stack em docs/DECISIONS.md
6. Atualize a secao 'Stack do Projeto' no CLAUDE.md
")
```

---

### PASSO 6 — Tech Lead cria contratos

```
Agent(subagent_type="tech-lead-agent", prompt="
Criacao de contratos. Os wireframes foram aprovados e a stack ja esta definida em DECISIONS.md.

Siga a secao 'Criacao de contratos' do seu agent file:
1. Para cada wireframe em docs/wireframes/{nome}.html, crie docs/contracts/{nome}.md
2. Cada contrato contem secoes ## API e ## Screen no mesmo arquivo
3. Schemas devem ser CONCRETOS (sem '...')
4. Antes de escrever um contrato, registre em DECISIONS.md (DEC-TL-XXX) qualquer escolha nao-trivial: padrao de auth, paginacao, formato de data, status codes, convencao de erro
5. Funcionalidades sem UI (jobs, webhooks) tambem viram contrato — so secao ## API populada
6. Liste contratos criados e adicione linha em PROGRESS.md
")
```

---

### PASSO 7 — PO Agent cria tarefas a partir dos contratos

```
Agent(subagent_type="po-agent", prompt="
FASE 2 — Criacao de tarefas. Wireframes aprovados, contratos criados.

Siga seu 'Protocolo de execucao (Fase 2)':
1. Liste docs/contracts/*.md
2. Liste board/todo/*.md (evitar duplicatas)
3. Leia docs/DECISIONS.md (stack ja definida)
4. Para CADA contrato, crie tarefas BACK e/ou FRONT em board/todo/{ID}.md:
   - Titulo deve usar o slug do contrato (ex: 'BACK-003: login')
   - Frontmatter padrao (id, type, priority, depends_on, created, updated)
   - Acceptance Criteria verificaveis (incluindo visuais para FRONT)
   - Context aponta para docs/contracts/{nome}.md (secao API ou Screen) e docs/wireframes/{nome}.html quando aplicavel
5. Para funcionalidades sem contrato (devops, scripts), crie tarefas DEVOPS sem referencia de contrato
6. Mapeie dependencias (depends_on)
7. Reporte backlog criado

PRD (referencia, mas a fonte de verdade agora sao os contratos):
{CONTEUDO_COMPLETO_DO_PRD}
")
```

---

### PASSO 8 — DevOps Agent faz scaffold do projeto

```
Agent(subagent_type="devops-agent", prompt="
Setup inicial: stack definida em docs/DECISIONS.md, contratos em docs/contracts/, tarefas em board/todo/.

Siga seu protocolo de scaffold:
1. Leia docs/DECISIONS.md para a stack completa
2. Crie a estrutura de pastas do projeto
3. Crie arquivos de configuracao (package.json, tsconfig, etc.)
4. Crie scripts de desenvolvimento (dev, build, test, lint)
5. Crie .env.example
6. Instale dependencias base
7. Configure infraestrutura de testes:
   - Unit: Jest/Vitest ou equivalente
   - Integration: Supertest/Testing Library
   - E2E: Playwright (instalar, criar playwright.config.ts)
   - Criar diretorios: tests/unit/, tests/integration/, tests/e2e/specs/, tests/e2e/screenshots/
8. Verifique que o projeto compila/roda sem erros
9. Registre decisoes de infra em docs/DECISIONS.md
10. Adicione entrada em docs/PROGRESS.md
")
```

---

### PASSO 9 — PO Agent injeta contexto e valida cobertura

```
Agent(subagent_type="po-agent", prompt="
Validacao final e injecao de contexto:

1. Releia docs/DECISIONS.md (stack final)
2. Para CADA arquivo de tarefa em board/todo/:
   - Leia o arquivo
   - Injete na secao '## Context' as decisoes de DECISIONS.md relevantes para ESTA tarefa
   - Garanta que o caminho do contrato (docs/contracts/{nome}.md) e do wireframe (se FRONT) estao presentes
   - Salve o arquivo atualizado
3. Verifique se TODAS as funcionalidades do PRD tem tarefa correspondente
4. Se encontrar gap: crie a tarefa faltante em board/todo/
5. Reporte cobertura final (deve ser 100%)

PRD:
{CONTEUDO_COMPLETO_DO_PRD}
")
```

---

### PASSO 10 — Apresente o resultado ao usuario

Liste `board/todo/`, `docs/wireframes/` e `docs/contracts/` e mostre:

```
Dev Team iniciado com sucesso!

Wireframes aprovados:
  - {N} telas em docs/wireframes/

Contratos:
  - {N} contratos em docs/contracts/

Backlog:
  - X tarefas [BACK] criadas
  - Y tarefas [FRONT] criadas
  - Z tarefas [DEVOPS] criadas
  - W tarefas sem dependencias (podem comecar agora)

Stack definida:
  [extrair da tabela Stack em DECISIONS.md]

Testes configurados:
  Unit: {framework}
  Integration: {framework}
  E2E: Playwright (fonte de verdade)

Estrutura do board:
  board/todo/      — {N} tarefas aguardando
  board/done/      — (vazio)
  board/verified/  — (vazio)

Proximo passo: /dev-team-next (uma tarefa) ou /dev-team-run (loop autonomo)
```
